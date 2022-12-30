pragma solidity ^0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract NFTMarketplaceAuction is Ownable {
  using SafeMath for uint256;

  // The address of the NFT contract
  address public nftContract;

  // The ID of the NFT being auctioned
  uint256 public nftId;

  // The current highest bidder
  address public highestBidder;

  // The current highest bid
  uint256 public highestBid;

  // The auction end time
  uint256 public auctionEnd;

  // Event that is emitted when the NFT is sold
  event NFTSold(address recipient, uint256 value);

  constructor(address _nftContract, uint256 _nftId, uint256 _auctionEnd) public {
    nftContract = _nftContract;
    nftId = _nftId;
    auctionEnd = _auctionEnd;
  }

  // Function to bid on the NFT
  function bid(uint256 _value) public payable {
    require(_value > highestBid, "Bid must be higher than the current highest bid");
    require(_value > 0, "Bid must be greater than 0");
    require(now <= auctionEnd, "Auction has already ended");

    // Transfer the bid amount from the bidder to the contract
    highestBidder.transfer(_value);

    // Update the highest bid and highest bidder
    highestBid = _value;
    highestBidder = msg.sender;
  }

  // Function to end the auction and sell the NFT
  function endAuction() public {
    require(now >= auctionEnd, "Auction has not yet ended");

    // Transfer the NFT to the highest bidder
    nftContract.safeTransferFrom(owner, highestBidder, nftId);

    // Emit the NFTSold event
    emit NFTSold(highestBidder, highestBid);
  }
}




























pragma solidity ^0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/SafeERC721.sol";

contract NFT Auction {
    using SafeMath for uint;
    using SafeERC721 for ERC721;

    ERC721 public nft;
    address public owner;

    // Map to store information about ongoing auctions
    mapping(uint => AuctionData) public auctions;
    uint public auctionCount;

    struct AuctionData {
        address seller;
        uint startTime;
        uint endTime;
        uint startingPrice;
        uint currentPrice;
        uint nftId;
        bool ended;
    }

    constructor(ERC721 _nft) public {
        owner = msg.sender;
        nft = _nft;
    }

    function createAuction(uint _nftId, uint _startingPrice, uint _duration) public {
        require(nft.ownerOf(_nftId) == msg.sender, "Only the owner of the NFT can create an auction");
        require(_startingPrice > 0, "Starting price must be greater than 0");
        require(_duration > 0, "Auction duration must be greater than 0");

        uint auctionId = auctionCount++;
        auctions[auctionId] = AuctionData(
            msg.sender,
            now,
            now.add(_duration),
            _startingPrice,
            _startingPrice,
            _nftId,
            false
        );
    }

    function bid(uint _auctionId, uint _bidAmount) public payable {
        require(msg.value >= _bidAmount, "Bid amount must be equal to or greater than the bid value");
        require(_bidAmount > auctions[_auctionId].currentPrice, "Bid amount must be greater than the current price");
        require(now >= auctions[_auctionId].startTime && now <= auctions[_auctionId].endTime, "Auction must be ongoing");

        // Transfer the currentPrice from the seller to the bidder
        auctions[_auctionId].seller.transfer(auctions[_auctionId].currentPrice);

        // Update the current price and the seller of the auction
        auctions[_auctionId].currentPrice = _bidAmount;
        auctions[_auctionId].seller = msg.sender;
    }

    // Other functions for ending auctions, etc.
}

pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/SafeERC721.sol";

// Replace "NFT" with the name of your NFT contract
contract NFTAuction is SafeERC721 {
    // The address of the owner of the auction contract
    address public contractOwner;

    // The address of the owner of the NFT being auctioned
    address public nftOwner;

    // The ID of the NFT being auctioned
    uint256 public nftId;

    // The current bid amount
    uint256 public bidAmount;

    // The address of the current highest bidder
    address public highestBidder;

    // The auction end time
    uint256 public auctionEndTime;

    // Event that is emitted when the auction is created
    event AuctionCreated(uint256 nftId, uint256 auctionEndTime);

    // Event that is emitted when a new bid is placed
    event NewBid(uint256 bidAmount, address bidder);

    // Event that is emitted when the auction ends
    event AuctionEnded(uint256 finalBidAmount, address winner);

    // Constructor function that initializes the contract
    constructor() public {
        contractOwner = msg.sender;
    }

    // Function that allows the owner of the NFT to create an auction for their NFT
    function createAuction(uint256 _nftId, uint256 _auctionEndTime) public {
        require(isApprovedOrOwner(msg.sender, _nftId), "You are not the owner or an approved operator of the NFT.");
        require(nftId == 0, "There is already an active auction.");

        nftOwner = msg.sender;
        nftId = _nftId;
        bidAmount = 0;
        highestBidder = address(0);
        auctionEndTime = _auctionEndTime;
        emit AuctionCreated(_nftId, _auctionEndTime);
    }

    // Function that allows a user to place a bid on the NFT
    function bid() public payable {
        require(now <= auctionEndTime, "The auction has already ended.");
        require(msg.value > bidAmount, "The bid must be higher than the current bid.");

        // Transfer ownership of the previous highest bidder's funds to the contract
        if (highestBidder != address(0)) {
            highestBidder.transfer(bidAmount);
        }

        // Update the current bid amount and highest bidder
        bidAmount = msg.value;
        highestBidder = msg.sender;

        emit NewBid(bidAmount, highestBidder);
    }

    // Function that ends the auction and transfers ownership of the NFT to the highest bidder
    function endAuction() public {
        require(now >= auctionEndTime, "The auction has not yet ended.");
        require(highestBidder != address(0), "There were no bids on the NFT.");

        // Transfer the NFT to the highest bidder
        safeTransferFrom(nftOwner, highestBidder, nft
