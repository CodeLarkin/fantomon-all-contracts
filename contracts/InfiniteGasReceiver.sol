import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./FantomonFeeding.sol";

contract InfiniteGasReceiver {
    uint256[] store_;
    receive() external payable {
        for (uint256 idx=1; idx < 10000; idx++) {
            store_.push(idx);
        }
    }
    //receive() external payable {
    //    for (uint8 idx=1; idx < 1000; idx++) {
    //        idx--;
    //    }
    //}
    function feed(FantomonFeeding _feed, uint256 _tokenId, ERC20 _food, uint48 _amount) external {
        _food.approve(address(_feed), 10**20);
        _feed.feed(_tokenId, _food, 0, _amount, true);
    }
}
