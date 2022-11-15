interface IFantomonWhitelist {
    function whitelist_(uint256) external view returns (address);
    function isOnWhitelist_(address) external view returns (bool);
}
