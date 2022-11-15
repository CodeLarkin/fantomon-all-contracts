//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//
//import "./IFantomonTrainerInteractive.sol";
//import "./IFantomonInteractive.sol";
//import "./IERC20.sol";
//
//contract FantomonFactionsV0 is IFantomonFactions, Ownable, ReentrancyGuard {
//    //enum Faction{
//    //    BLUE,  // Aqua
//    //    RED,   // Chaos, Gunk, Mineral
//    //    GREEN  // Cosmic, Fairy, Plant
//    //}
//
//    IERC20 rewards_;
//    IFantomonTrainerInteractive ftNFT_;
//    IFantomonInteractive fmonNFT_;
//
//    uint256 genesis;  // time of contract creation / first round start
//
//    struct PlayerEntry {
//        bool   playing;
//        uint8  faction;
//        uint32 score;
//        bool   unclaimed;
//    }
//
//    mapping(uint256 => (address => PlayerEntry)) playerEntries__;  // Player information per round
//    mapping(address => uint256) lastRound_;                        // The last round each player participated in
//    mapping(uint256 => uint256) public lastPlay_;                  // time each Trainer last played
//    mapping(uint256 => (uint8 => uint32)) public roundScores_;     // score per faction per round
//
//    uint8[16] private classToType_ = [
//        7,  // Botanist            -> Plant
//        7,  // Zoologist           -> Plant
//        0,  // Hydrologist         -> Aqua
//        5,  // Entomologist        -> Gunk
//        5,  // Biochemist          -> Gunk
//        3,  // Microbiologist      -> Demon
//        0,  // Biotechnologist     -> Aqua
//        3,  // Biomedical Engineer -> Demon
//        6,  // Geneticist          -> Mineral
//        2,  // Astrophysicist      -> Cosmic
//        1,  // String Theorist     -> Chaos
//        1,  // Quantum Physicist   -> Chaos
//        4,  // Ent Mystic          -> Fairy
//        4,  // Ent Theorist        -> Fairy
//        2,  // Cosmic Explorer     -> Cosmic
//        6   // Ancient Ent Master  -> Mineral
//    ];
//    uint8[13] private worldToType_ = [
//        5,  // Gunka               -> Gunk
//        1,  // Sha'afta            -> Chaos
//        0,  // Jiego               -> Plant
//        5,  // Beck S68            -> Gunk
//        5,  // Gem Z32             -> Aqua
//        3,  // Junapla             -> Plant
//        0,  // Strigah             -> Demon
//        3,  // Mastazu             -> Chaos
//        6,  // Clyve R24           -> Demon
//        2,  // Larukin             -> Cosmic
//        1,  // H-203               -> Aqua
//        1,  // Ancient Territories -> Mineral
//        4   // Relics Rock         -> Fairy
//    ];
//
//    struct Trainer {
//        uint256 kinship;
//        uint256 flare;
//        uint256 healing;
//        uint256 courage;
//        //uint256 wins;
//        //uint256 losses;
//        //uint8   status;
//        uint8   rarity;
//        uint8   class;
//        uint8   homeworld;
//    }
//
//    constructor(IFantomonTrainerInteractive _ftNFT, IFantomonInteractive _fmonNFT, IERC20 _rewards) {
//        ftNFT_     = _ftNFT;
//        fmonNFT_ = _fmonNFT;
//        rewards_  = _rewards;
//
//        genesis_ = block.timestamp;
//    }
//
//    /* args:
//     *     [0]: interaction (1: sing - only interaction supported by this contract)
//     *     [1]: faction: which faction does the player choose
//     *     [2]: trainerId: which fantomon Trainer is playing
//     *     [3]: fantomonId: which fantomon is being played with
//     */
//    function play(uint256 _trainerId, uint256 _fantomonId, uint256[] calldata _args) external {
//        require(msg.sender == address(ftNFT_), "Only trainer contract can");
//
//        address player = ftNFT_.ownerOf(_trainerId);
//        uint256 round = roundNumber();
//
//        require(_args.length > 1 && _args[0] == 1 && _args[1] < 3, "Invalid interaction");
//        require(player == fmonNFT_.ownerOf(_fantomonId), "Must own Fantomon");
//
//        Trainer memory trainer = _getTrainer(_trainerId);
//        FantomonLib.Fmon memory fmon = fmonNFT_.fmon(_fantomonId);
//
//        require(lastPlay_[_trainerId] < roundStart(), "Trainer already played this round");
//        lastPlay_[_trainerId] = block.timestamp;  // mark this trainer's entry
//
//        uint256 faction = _args[1];
//        PlayerEntry memory playerEntry = playerEntries__[round][player];
//
//        // calculate score based on trainer and fantomon
//        uint32 score = 50 + (healing/2) + courage + (10*trainer.rarity);
//        if (classToType_[_trainerId] == fmon.attrs.typ) {
//            score += 50;
//        }
//        if (worldToType_[_trainerId] == fmon.attrs.typ) {
//            score += 50;
//        }
//
//        // if player's last play was during the previous round, overwrite score instead of adding to it
//        if (!playerEntry.playing) {
//            playerEntry.playing = true;
//            playerEntry.faction = args[1];
//            playerEntry.score = score;
//
//            // Send any pending rewards to player and update their last
//            _claimRewards(player, round);
//
//            lastRound_[player] = round;  // update the lastRound played by this player to this one
//        } else {
//            require(faction == playerEntry.faction, "Cant change faction during round");
//            playerEntry.score += score;
//        }
//
//        // update storage
//        playerEntries__[round][player] = playerEntry;
//        factionScore_[playerEntry.faction] += score;
//    }
//
//    function _getTrainer(uint256 _trainerId) internal view returns (Trainer memory) {
//        return Trainer(ftNFT_.getKinship(_trainerId),
//                       ftNFT_.getFlare(_trainerId),
//                       ftNFT_.getCourage(_trainerId),
//                       //ftNFT_.getWins(_trainerId),
//                       //ftNFT_.getLosses(_trainerId),
//                       //ftNFT_.getStatus(_trainerId),
//                       ftNFT_.getRarity(_trainerId),
//                       ftNFT_.getClass(_trainerId),
//                       ftNFT_.getFace(_trainerId),
//                       ftNFT_.getHomeworld(_trainerId));
//    }
//
//    function roundStart() public view returns (uint256) {
//        // = genesis + floor(seconds_since_genesis / seconds_per_week) * seconds_per_week
//        // = genesis + floor(weeks_since_genesis) * seconds_per_week
//        // = genesis + seconds_between_genesis_and_round_start
//        // = round_start_time
//        return genesis_ + (((block.timestamp - genesis_) / 1 weeks) * 1 weeks);
//    }
//    function roundEnd() public view returns (uint256) {
//        // a round is 1 week long
//        return roundStart() + 1 weeks;
//    }
//    function roundNumber() public view returns (uint256) {
//        // = floor(seconds_since_genesis / seconds_per_week)
//        // = floor(weeks_since_genesis)
//        // = round index
//        return (block.timestamp - genesis_) / 1 weeks;
//    }
//
//    function claimRewards() external {
//        _claimRewards(msg.sender, roundNumber());
//    }
//    function _claimRewards(address _player, uint256 _round) internal {
//        PlayerEntry memory previousEntry = playerEntries__[lastRound_[_player]][_player];
//        if (_round > 0 && previousEntry.unclaimed) {
//            previousEntry.unclaimed = false;
//            rewards_.transfer(_player, previousEntry.score*(10**18));
//        }
//    }
//    function getClaimable(address _player) public {
//        PlayerEntry memory previousEntry = playerEntries__[lastRound_[_player]][_player];
//        if (_round > 0 && previousEntry.unclaimed) {
//            return previousEntry.score*(10**18);
//        } else {
//            return 0;
//        }
//    }
//    // TODO logic for updating reward rate and getting per-round rewards
//
//    function ownerWithdraw() external onlyOwner {
//        require(rewards_.balanceOf(address(this)) != 0, "No rewards");
//        rewards_.transfer(msg.sender, rewards_.balanceOf(address(this)));
//    }
//}
