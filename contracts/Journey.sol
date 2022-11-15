// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//import "./Fantomons.sol";
import "./FantomonTrainer.sol";
import "./IFantomonLocation.sol";

import "hardhat/console.sol";

contract Journey is IFantomonLocation {
    FantomonTrainer _fts;

    //uint8 constant private RESTING = 0;
    //uint8 constant private PREPARING = 1;
    //uint8 constant private BATTLING = 2;
    //uint8 constant private HEALING = 3;
    uint8 constant private LOST = 4;

    uint256 public numTrainersLostHere_ = 0;
    mapping (uint256 => bool) public lost_;

    // Modifiers
    modifier isLost(uint256 _trainer) {
        require(lost_[_trainer], "Trainer isn't currently lost here");
        _;
    }
    modifier onlyTrainerOwner(uint256 _trainer) {
        require(_fts.ownerOf(_trainer) == msg.sender, "You don't own that trainer");
        _;
    }
    modifier onlyTrainerContract() {
        require(address(_fts) == msg.sender, "Only the FantomonTrainer contract can do that");
        _;
    }
    function isLostHere(uint256 _trainer) internal returns (bool) {
        return (_fts.getStatus(_trainer) == LOST && _fts.location_(_trainer) == address(this));
    }



    //constructor (address _fantomons, address _trainers) {
    constructor (address _trainers) {
        //_fms = Fantomons(_fantomons);
        _fts = FantomonTrainer(_trainers);
    }

    // args[]: don't care
    function enter(uint256 _trainer, uint256[] calldata _args) external override onlyTrainerContract() {
        //require(!lost_[_trainer], "Trainer already healing");
        if (!lost_[_trainer]) {
            lost_[_trainer] = true;
            numTrainersLostHere_++;
        }
        emit BeganJourney(_trainer);
    }

    function _exit(uint256 _trainer) internal {
        _fts._leaveJourney(_trainer);
        lost_[_trainer] = false;
        numTrainersLostHere_--;
        emit EndedJourney(_trainer);
    }

    function leave(uint256 _trainer) external onlyTrainerOwner(_trainer) {
        _fts._leaveJourney(_trainer);
        lost_[_trainer] = false;
        numTrainersLostHere_--;
        emit EndedJourney(_trainer);
    }

    function quit(uint256 _trainer) external onlyTrainerOwner(_trainer) {
        _fts._leave(_trainer);
        lost_[_trainer] = false;
        numTrainersLostHere_--;
        emit EndedJourney(_trainer);
    }

    // Exit gracefully - called by the FantomonTrainer contract
    // Lets you flee via the FantomonTrainer contract, but still
    // trigger cleanup here. Cleaner than emergencyFlee
    function flee(uint256 _trainer) external override onlyTrainerContract {
        lost_[_trainer] = false;
        numTrainersLostHere_--;
        emit EndedJourney(_trainer);
    }

    event BeganJourney(uint256 trainer);
    event EndedJourney(uint256 trainer);
}
