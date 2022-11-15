import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./FantomonFeeding.sol";

contract Unpayable {
    function feed(FantomonFeeding _feed, uint256 _tokenId, ERC20 _food, uint48 _amount) external {
        _food.approve(address(_feed), 10**20);
        _feed.feed(_tokenId, _food, 0, _amount, true);
    }
}
