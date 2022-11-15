interface IFantomonNaming {
    function names_(uint256) external view returns (string calldata);
    function nameTaken_(string calldata) external view returns (bool);
}
