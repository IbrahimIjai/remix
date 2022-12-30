// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract DistanceFiBET is ReentrancyGuard{

    using EnumerableSet for EnumerableSet.AddressSet;
    enum Choices {None, HomeWin, AwayWin, DrawGame }
    address public admin;
    struct Results {
        uint Home_score;
        uint Away_score;
    }
    struct Match {
        string HomeTeam;
        string AwayTeam;
        uint startTime;
        uint endTime;
        Results results;
        Choices gameResult;
    }
    struct Bettor{
        Choices bet;
        uint winAmounts;
        uint betAmount;
        bool played;
    }
    mapping (uint => Match) public Game;
    mapping (address => mapping (uint => Bettor)) public userBet;
    Match [] public allMatch;
    struct allBets{
        address bettor;
        uint amount;
        Choices choice;
    }
    allBets[] public specificMatchBets;

 
    constructor(){
        admin = msg.sender;
    }

    function instantiateMatch(string calldata _HomeTeam, string calldata _AwayTeam, uint _startTime) external returns (bool) {
        require(admin == msg.sender, "Not Owner");
        uint matchEnd = _startTime + 95 seconds;
        Results memory startingResults = Results(0, 0);
        uint game = allMatch.length;
        Game[game] = Match(_HomeTeam, _AwayTeam, _startTime, matchEnd, startingResults, Choices.None);
        allMatch.push(Match(_HomeTeam, _AwayTeam, _startTime, matchEnd, startingResults, Choices.None));
        return true;
    }

    function closeMatch(uint epoch, uint _homeScore, uint _awayScore) external nonReentrant {
        require(admin == msg.sender, "Not Owner");
        uint currentTime = block.timestamp;
        require(currentTime >= allMatch[epoch].endTime, "Match is still on");
        Results memory closingResults = Results(_homeScore, _awayScore);
        allMatch[epoch].results = closingResults;
        Game[epoch].results = closingResults;
        
    }

    function placeBet(uint epoch, Choices _betChoice) payable external nonReentrant {
        require(userBet[msg.sender][epoch].played == false, "You can only play once! Update instead");
         require(msg.value == 1 ether, "Bet Amount is less than required");    
        uint currentTime = block.timestamp;
        require(currentTime < Game[epoch].startTime, "Game has started");
        uint _betAmount = msg.value;
        userBet[msg.sender][epoch] = Bettor(_betChoice, 0, _betAmount, true);
        // specificMatchBets[epoch] = allBets(msg.sender, _betAmount, _betChoice);
    }

    function updateBet(uint epoch, Choices _betChoice) external nonReentrant  {
        uint currentTime = block.timestamp;
        require(currentTime < Game[epoch].startTime, "Game has already begun"); 
        require(userBet[msg.sender][epoch].played == true, "You can only update once played!");
       userBet[msg.sender][epoch].bet = _betChoice;

    }

    function _checkMatchResult(uint epoch, uint _homeScore, uint _awayScore) internal  {
        if (_homeScore > _awayScore) {
        allMatch[epoch].gameResult = Choices.HomeWin;
        Game[epoch].gameResult = Choices.HomeWin;            
        } else if (_homeScore < _awayScore) {
        allMatch[epoch].gameResult = Choices.AwayWin;
        Game[epoch].gameResult = Choices.AwayWin;
        } else {
        allMatch[epoch].gameResult = Choices.DrawGame;
        Game[epoch].gameResult = Choices.DrawGame;    
        }
    }

    function _calculateGameWinners(uint epoch, Choices _gameResult) internal {
    }

}