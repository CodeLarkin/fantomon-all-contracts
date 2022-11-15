// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The ERC721 MasterChef is a fork of MasterChef by SushiSwap
// The biggest change made is to support ERC721s instead of ERC20s
// for staking, and using per-second instead of per-block for rewards
// This is due to Fantoms extremely inconsistent block times.
//
// The `MasterChef721` contract functions similar to a ERC20 MasterChef, except for a few critical differences:
//
// 1. Each `user` (each UserInfo struct instance) corresponds to a tokenId of an ERC721
// 2. Each `pool` and corresponds to a different ERC721 (NFT Collection), and the corresponding `lp` (as in `lpToken`) is an ERC721 address.
// 3. The contract is non-custodial and simply keeps track of which tokenIds have been deposited by making the corresponding `userInfo.amount` greater than 1
// 4. Since the contract is non-custodial and pending rewards need to be summed per-tokenId when a user claims rewards, there is a separate function `claimRewards` instead of using the classic MasterChef route of `deposit(pid, 0)` performing a claim. `deposit` no longer claims rewards.
// 5. By default each tokenId in a collection receives equal rewards, but via the `setBoosts(pid...)`, specific tokenIds can get a rewards multiplier (2x, 3x ...).
// 6. `deposit()`, `pendingRewards()`, `claimRewards()` and `withdraw()` all operate on a list of tokenIds. In other words, a user deposits a specific set of tokenIds, and then specifies those tokenIds when claiming rewards or withdrawing.

contract MasterChef721 is Ownable {

    // Info of each user. Note: a "user" here is really a tokenId. This struct is left similar to the classic MasterChef to make for easier compatibility with dapps
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided. Note: this is really just a per-tokenId multiplier for the 721 chef
        uint256 rewardDebt; // Reward debt. See explanation below.
        // Any point in time, the amount of rewards
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        bool hasBoosts;
        IERC721 lpToken;             // Address of LP token contract for this pool. Note: this is really the NFT collection, but is left as 'lpToken' to more easily maintain parallels and compatibility with classic MasterChef dapps
        uint256 allocPoint;          // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardTime;      // Last block time that rewards distribution occurs.
        uint256 accRewardsPerShare;  // Accumulated rewards per share, times 1e12. See below.
        uint256 tokensStaked;        // How many tokens have been staked here - need this instead of balanceOf since non-custodial
    }

    // the token being distributed as rewards
    IERC20Mintable public rewardToken;

    // rewardToken tokens created per second
    uint256 public rewardsPerSecond;

    // set a max rewards per second, which can never be higher than 1 per second
    uint256 public constant maxRewardsPerSecond = 1e18;

    uint256 public constant MaxAllocPoint = 4000;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The block time when rewards mining starts and ends.
    uint256 public immutable startTime;

    uint256 public endTime;

    // Info of each pool.
    // There is one pool per 721/NFT-collection
    PoolInfo[] public poolInfo;

    // For each pool/LP (NFT collection), which token IDs should have boosted rewards, and by what mulitplier
    // Boost of 0 just means 'no boost/multiplier'. Boost of 1 = 2x rewards, 2 = 3x rewards...
    // Note: if boost changes post-deposit, staker must withdraw and redeposit to update their rewards multiplier
    mapping (uint256 => mapping (uint256 => uint256)) public boostedTokens;

    // Info of each user that stakes LP tokens.
    // For this 721 version of MasterChef, this is really per-tokenId info for each pool
    mapping (uint256 => mapping (uint256 => UserInfo)) public userInfo;

    error DontOwn(address sender, uint256 pid, uint256 tokenId);
    error NotStaked(address sender, uint256 pid, uint256 tokenId);
    error AlreadyStaked(address sender, uint256 pid, uint256 tokenId);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20Mintable _rewardToken,
        uint256 _rewardsPerSecond,
        uint256 _startTime,
        uint256 _endTime
    ) {
        rewardToken = _rewardToken;
        rewardsPerSecond = _rewardsPerSecond;
        startTime = _startTime;
        endTime = _endTime;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    // Changes rewardToken reward per second, with a cap of maxrewards per second
    // Good practice to update pools without messing up the contract
    function setRewardsPerSecond(uint256 _rewardsPerSecond) external onlyOwner {
        require(_rewardsPerSecond <= maxRewardsPerSecond, "setRewardsPerSecond: rewards > max!");

        // This MUST be done or pool rewards will be calculated with new rewards per second
        // This could unfairly punish small pools that dont have frequent deposits/withdraws/harvests
        massUpdatePools();

        rewardsPerSecond = _rewardsPerSecond;
    }

    function checkForDuplicate(IERC721 _lpToken) internal view {
        uint256 length = poolInfo.length;
        for (uint256 _pid; _pid < length; ) {
            require(poolInfo[_pid].lpToken != _lpToken, "add: pool already exists!");
            unchecked { ++_pid; }
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC721 _lpToken) external onlyOwner {
        require(_allocPoint <= MaxAllocPoint, "add: too many alloc points!!");

        checkForDuplicate(_lpToken); // ensure you cant add duplicate pools

        massUpdatePools();

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accRewardsPerShare: 0,
            tokensStaked: 0,
            hasBoosts: false
        }));
    }

    // Update the given pool's rewards allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        require(_allocPoint <= MaxAllocPoint, "add: too many alloc points!!");

        massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set per-tokenId boosts/multipliers for an LP (721). Optional.
    function setBoosts(uint256 _pid, uint256[] memory _boostedIds, uint256[] memory _boosts) external onlyOwner {
        require(_boostedIds.length == _boosts.length, "array of ids & their boosts different length");

        poolInfo[_pid].hasBoosts = true;

        for (uint i; i < _boostedIds.length;) {
            require(_boosts[i] <= 100, "Boost should be <= 100");
            boostedTokens[_pid][_boostedIds[i]] = _boosts[i];
            unchecked { ++i; }
        }
    }

    // Note: disable all boosts - if boosts are reenabled, old boosts will remain in effect
    function disableBoosts(uint256 _pid) external onlyOwner {
        poolInfo[_pid].hasBoosts = false;
    }


    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // Rewards only exist within the startTime -> endTime window
        // Clip from -> to window to fit the rewards range
        _from = _from > startTime ? _from : startTime;
        _to   = _to < endTime ? _to : endTime;

        if (_to < startTime) {
            return 0;  // rewards have not started
        } else if (_from >= endTime) {
            return 0;  // rewards have ended
        } else {
            return _to - _from;
        }
    }

    // View function to see pending rewards on frontend.
    function pendingRewards(uint256 _pid, uint256[] memory _tokenIds) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        // Pull relevant pool info into memory post-update
        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 lpSupply = pool.tokensStaked;

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 rewards = multiplier * rewardsPerSecond * pool.allocPoint / totalAllocPoint;
            accRewardsPerShare += rewards * 1e12 / lpSupply;
        }

        uint256 pending = 0;
        for (uint256 i; i < _tokenIds.length;) {
            UserInfo storage user = userInfo[_pid][_tokenIds[i]];
            pending += user.amount * accRewardsPerShare / 1e12 - user.rewardDebt;
            unchecked { ++i; }
        }
        return pending;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length;) {
            updatePool(pid);
            unchecked { ++pid; }
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) return;

        uint256 lpSupply = pool.tokensStaked;
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 rewards = multiplier * rewardsPerSecond * pool.allocPoint / totalAllocPoint;

        rewardToken.mint(address(this), rewards);

        pool.accRewardsPerShare = pool.accRewardsPerShare + rewards * 1e12 / lpSupply;
        pool.lastRewardTime = block.timestamp;
    }

    // Claim rewards for the specified tokenIds of the specified pool/721.
    function claimRewards(uint256 _pid, uint256[] memory _tokenIds) public {
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);

        // Pull relevant pool info into memory post-update
        IERC721 lpToken = pool.lpToken;
        uint256 accRewardsPerShare = pool.accRewardsPerShare;

        uint256 pending;
        for (uint256 i; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            UserInfo storage user = userInfo[_pid][tokenId];

            if (lpToken.ownerOf(tokenId) != msg.sender) revert DontOwn(msg.sender, _pid, tokenId);

            uint256 amount = user.amount;

            // user.amount > 0 for a tokenId means that it is staked
            if (amount == 0) revert NotStaked(msg.sender, _pid, tokenId);

            pending += amount * accRewardsPerShare / 1e12 - user.rewardDebt;

            user.rewardDebt = amount * accRewardsPerShare / 1e12;

            unchecked { ++i; }
        }
        if (pending > 0) {
            safeRewardTokenTransfer(msg.sender, pending);
            emit Claim(msg.sender, _pid, pending);
        }
    }

    // Deposit LP tokens to MasterChef for rewards allocation.
    // Since this version of the chef is non-custodial, just flag each tokenId's
    // `userInfo.amount` as > 0 to flag it as staked.
    function deposit(uint256 _pid, uint256[] memory _tokenIds) public {
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);

        // Pull relevant pool info into memory post-update
        IERC721 lpToken = pool.lpToken;
        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        bool hasBoosts = pool.hasBoosts;

        uint256 newlyStaked;
        for (uint256 i; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            UserInfo storage user = userInfo[_pid][tokenId];

            if (lpToken.ownerOf(tokenId) != msg.sender) revert DontOwn(msg.sender, _pid, tokenId);
            // user.amount > 0 for a tokenId means that it is staked
            if (user.amount > 0) revert AlreadyStaked(msg.sender, _pid, tokenId);

            // (don't need to do transfer tokens to this contract - just set amount to 0)
            uint256 amount = hasBoosts ? 1 + boostedTokens[_pid][tokenId] : 1;

            newlyStaked += amount;
            user.amount = amount;

            user.rewardDebt = amount * accRewardsPerShare / 1e12;

            unchecked { ++i; }
        }

        if (newlyStaked > 0) {
            pool.tokensStaked += newlyStaked;
        }

        emit Deposit(msg.sender, _pid, newlyStaked);
    }

    // Withdraw LP tokens from MasterChef.
    // For this 721 version, this just stops the specified tokenIds from receiving rewards.
    // Withdraw triggers 'claimRewards' as well.
    function withdraw(uint256 _pid, uint256[] memory _tokenIds) public {
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);

        // Pull relevant pool info into memory post-update
        IERC721 lpToken = pool.lpToken;
        uint256 accRewardsPerShare = pool.accRewardsPerShare;

        uint256 pending;
        uint256 amountUnstaked;
        for (uint256 i; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            UserInfo storage user = userInfo[_pid][tokenId];

            if (lpToken.ownerOf(tokenId) != msg.sender) revert DontOwn(msg.sender, _pid, tokenId);

            uint256 amount = user.amount;
            // user.amount > 0 for a tokenId means that it is staked
            if (amount == 0) revert NotStaked(msg.sender, _pid, tokenId);

            pending += amount * accRewardsPerShare / 1e12 - user.rewardDebt;
            amountUnstaked += amount;

            user.rewardDebt = amount * accRewardsPerShare / 1e12;
            user.amount = 0;

            unchecked { ++i; }
        }

        pool.tokensStaked -= amountUnstaked;

        if (pending > 0) safeRewardTokenTransfer(msg.sender, pending);

        emit Withdraw(msg.sender, _pid, _tokenIds.length);
    }

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough rewards.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            rewardToken.transfer(_to, rewardBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
}
