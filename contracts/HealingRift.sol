/*
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░

░█████╗░███╗░░██╗██████╗░  ██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██╔══██╗████╗░██║██╔══██╗  ██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
███████║██╔██╗██║██║░░██║  ██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██╔══██║██║╚████║██║░░██║  ██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
██║░░██║██║░╚███║██████╔╝  ███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░  ╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IFantomonTrainerInteractive.sol";
import "./IFantomonLocation.sol";


contract HealingRift is IFantomonLocation, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IFantomonTrainerInteractive fts_;
    IERC20 eg_;

    //uint8 constant private RESTING   = 0;
    //uint8 constant private PREPARING = 1;
    //uint8 constant private BATTLING  = 2;
    uint8 constant private HEALING     = 3;
    //uint8 constant private LOST      = 4;

    uint256 constant private MIN_LEG_RARITY = 3;
    uint256 constant private MIN_LEG_CLASS  = 12;
    uint256 constant private MIN_LEG_WORLD  = 11;

    uint256 private BASE_REWARDS_PER_SECOND_E18 = 1157407407407407;  // 100 per day = 0.0011574 per hour (e18 for 18 decimals)
    uint256[] private histRates_;
    uint256[] private rateEndTimes_;

    uint256 public numTrainersHealing_ = 0;
    mapping (uint256 => bool) public healing_;
    mapping (uint256 => uint256) public entered_;

    // Modifiers
    modifier onlyTrainerOwner(uint256 _trainer) {
        require(fts_.ownerOf(_trainer) == msg.sender, "You don't own that trainer");
        _;
    }
    modifier onlyTrainerContract() {
        require(address(fts_) == msg.sender, "Only the FantomonTrainer contract can do that");
        _;
    }

    constructor (address _trainers, address _entgunk) {
        fts_ = IFantomonTrainerInteractive(_trainers);
        eg_  = IERC20(_entgunk);
    }

    function setRewardsRate(uint256 _rewardsPerSecondE18) external onlyOwner {
        histRates_.push(BASE_REWARDS_PER_SECOND_E18);
        rateEndTimes_.push(block.timestamp);
        BASE_REWARDS_PER_SECOND_E18 = _rewardsPerSecondE18;
    }

    // args[]: don't care
    function enter(uint256 _trainer, uint256[] calldata _args) external override onlyTrainerContract() {
        require(!healing_[_trainer], "Trainer already healing"); // cannot do this because of emergency flee


        if (!healing_[_trainer]) {
            numTrainersHealing_ = numTrainersHealing_.add(1);
            healing_[_trainer] = true;
        }
        entered_[_trainer] = block.timestamp;
    }

    function getRateMultiplier(uint256 _trainer) public view returns (uint256) {
        uint256 mult = 1;
        if (fts_.getRarity(_trainer) == MIN_LEG_RARITY) {
            mult = mult.mul(2);
        }
        if (fts_.getClass(_trainer) >= MIN_LEG_CLASS) {
            mult = mult.mul(2);
        }
        if (fts_.getHomeworld(_trainer) >= MIN_LEG_WORLD) {
            mult = mult.mul(2);
        }
        return mult;
    }

    function _getHistRewardsRatePerSecondE18(uint256 _trainer, uint256 _rate) internal view returns (uint256) {
        return _rate.mul(getRateMultiplier(_trainer));
    }

    function getRewardsRatePerSecondE18(uint256 _trainer) public view returns (uint256) {
        return BASE_REWARDS_PER_SECOND_E18.mul(getRateMultiplier(_trainer));
    }

    function getRewards(uint256 _trainer) public view returns (uint256) {
        if (healing_[_trainer] && fts_.getStatus(_trainer) == HEALING && fts_.location_(_trainer) == address(this)) {
            uint256 rewards = 0;
            uint256 startTime = entered_[_trainer];

            uint256 idx;
            for (idx = 0; idx < rateEndTimes_.length; idx++) {
                if (startTime < rateEndTimes_[idx]) {
                    //        rewards + ((rateEndTimes_[idx] - startTime) * _getHistRewardsRatePerSecondE18(_trainer, histRates_[idx]))
                    rewards = rewards.add((rateEndTimes_[idx].sub(startTime)).mul(_getHistRewardsRatePerSecondE18(_trainer, histRates_[idx])));
                    startTime = rateEndTimes_[idx];
                }
            }
            //     (rewards + ((block.timestamp - startTime) * getRewardsRatePerSecondE18(_trainer))) / 1 seconds;
            return (rewards.add((block.timestamp.sub(startTime)).mul(getRewardsRatePerSecondE18(_trainer)))).div(1 seconds);
        } else {
            return 0;
        }
    }
    function getClaimableRewards(uint256 _trainer) public view returns (uint256) {
        uint256 rewards = getRewards(_trainer);
        if (eg_.balanceOf(address(this)) >= rewards) {
            return rewards;
        }
        return 0;
    }

    function claimRewards(uint256 _trainer) public {
        require(fts_.ownerOf(_trainer) == msg.sender || address(fts_) == msg.sender, "You don't own that trainer");
        uint256 rewards = getRewards(_trainer);
        // make sure the contract has been alotted enough rewards for this claim
        require(eg_.balanceOf(address(this)) >= rewards, "Rewards have stopped");
        // reset reward balance to 0
        entered_[_trainer] = block.timestamp;
        // send rewards to msg.sender
        eg_.transfer(fts_.ownerOf(_trainer), rewards);
    }

    function getMultiRewardsRatePerSecondE18(uint256[] memory _trainers) public view returns (uint256) {
        uint256 rate = 0;
        uint256 idx;
        for (idx = 0; idx < _trainers.length; idx++) {
            if (healing_[_trainers[idx]] && fts_.getStatus(_trainers[idx]) == HEALING && fts_.location_(_trainers[idx]) == address(this)) {
                rate = rate.add(BASE_REWARDS_PER_SECOND_E18.mul(getRateMultiplier(_trainers[idx])));
            }
        }
        return rate;
    }
    function getMultiRewards(uint256[] memory _trainers) public view returns (uint256) {
        uint256 rewards = 0;
        uint256 idx;
        for (idx = 0; idx < _trainers.length; idx++) {
            rewards = rewards.add(getRewards(_trainers[idx]));
        }
        return rewards;
    }
    function getMultiClaimableRewards(uint256[] memory _trainers) public view returns (uint256) {
        uint256 rewards = 0;
        uint256 idx;
        for (idx = 0; idx < _trainers.length; idx++) {
            rewards = rewards.add(getClaimableRewards(_trainers[idx]));
        }
        return rewards;
    }

    function multiClaimRewards(uint256[] memory _trainers) public {
        uint256 rewards = 0;
        uint256 idx;
        for (idx = 0; idx < _trainers.length; idx++) {
            require(fts_.ownerOf(_trainers[idx]) == msg.sender, "You don't own that trainer");
            rewards = rewards.add(getRewards(_trainers[idx]));
            entered_[_trainers[idx]] = block.timestamp;
        }
        require(eg_.balanceOf(address(this)) >= rewards, "Rewards have stopped");
        eg_.transfer(msg.sender, rewards);
    }

    // Leave gracefully from the rift. Also, this should be called after emergencyFlee if a trainer wishes to reenter
    function leave(uint256 _trainer) external onlyTrainerOwner(_trainer) nonReentrant {
        require(healing_[_trainer], "Trainer isn't healing here");

        if (fts_.getStatus(_trainer) == HEALING && fts_.location_(_trainer) == address(this)) {
            claimRewards(_trainer);
            fts_._leaveHealingRift(_trainer);
        }
        healing_[_trainer] = false;
        numTrainersHealing_ = numTrainersHealing_.sub(1);
    }

    function multiLeave(uint256[] memory _trainers) external nonReentrant {
        uint256 numLeft = 0;
        uint256 idx;
        for (idx = 0; idx < _trainers.length; idx++) {
            require(fts_.ownerOf(_trainers[idx]) == msg.sender, "You don't own that trainer");
            if (healing_[_trainers[idx]] && fts_.getStatus(_trainers[idx]) == HEALING && fts_.location_(_trainers[idx]) == address(this)) {
                claimRewards(_trainers[idx]);
                fts_._leaveHealingRift(_trainers[idx]);
                healing_[_trainers[idx]] = false;
                numLeft = numLeft.add(1);
            }
        }
        numTrainersHealing_ = numTrainersHealing_.sub(numLeft);
    }

    // basically an alias for leave but called from the trainer contract instead of by user
    function flee(uint256 _trainer) external override onlyTrainerContract {
        // remember, emergencyFlee forfeits rewards!
        require(healing_[_trainer], "Trainer isn't healing here");

        if (fts_.getStatus(_trainer) == HEALING && fts_.location_(_trainer) == address(this)) {
            claimRewards(_trainer);
        }
        healing_[_trainer] = false;
        numTrainersHealing_ = numTrainersHealing_.sub(1);
    }

    function withdrawEntGunk() external onlyOwner {
        require(eg_.balanceOf(address(this)) != 0, "Contract has no EntGunk");
        eg_.transfer(msg.sender, eg_.balanceOf(address(this)));
    }
}
