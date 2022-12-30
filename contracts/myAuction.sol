// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}
interface IKRC20 is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IWKCS {
    function deposit() external payable;

    function withdraw(uint256) external;

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address to, uint256 value) external returns (bool);
}

contract AuctionMart {
    uint public nftId;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;

    mapping(address => uint) public bids;

    error NFTAlreadyBeingAuctioned(uint256 tokenId);

    struct Collection {
        address collectionAddress;
        uint256 royaltyFees;
    }

    struct Auction  {
        address Auctioner;
        uint256 minBid;
        bool  started;
        uint  startTime;
        bool  ended;
        uint highestBid;
        address highestBidder;
    }

    mapping(address => mapping(uint256 => Auction)) public AuctionedNft;
    mapping(address => EnumerableSet.UintSet) private tokenIdExists;
    mapping(address => uint256) public bidsTracker;
    // mapping(address => EnumerableSet.UintSet) private BidExist;
    mapping(address => Collection) public collection;

    EnumerableSet.AddressSet private collectionAddresses;

    modifier auctionOngoing(address CollectionAddress, uint256 tokenId) {
        require(
            tokenIdExists[CollectionAddress].contains(tokenId),
            "NFT isn't up for auction"
        );
        _;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor (){
        address owner = msg.sender;
    }





    function startAuction(
        address ,
        uint256 tokenId,
        uint minBid,
        bool started,
        uint startTime,
        bool  endAt
    ) external {
        IERC721 nft = IERC721(CollectionAddress);
        require(_msgSender() == nft.ownerOf(_tokenId), "msg.sender != owner");

        require(
            collectionAddresses.contains(CollectionAddress),
            "Collection is not listed"
        );

        if (tokenIdExists[_collection].contains(_tokenId)) {
            revert NFTAlreadyBeingAuctioned(_tokenId);
        }
        require(!AuctionedNft[CollectionAddress][tokenId].started, "started");

        AuctionedNft[CollectionAddress][tokenId].Auctioner = Auction(msg.sender );

        AuctionedNft[CollectionAddress][tokenId].minBid = minBid;

        AuctionedNft[CollectionAddress][tokenId].started = true;

        AuctionedNft[CollectionAddress][tokenId].startTime = block.timestamp;

        AuctionedNft[CollectionAddress][tokenId].endAt = AuctionedNft[CollectionAddress][tokenId].startTime + 259200;
        
        while (block.timestamp = AuctionedNft[CollectionAddress][tokenId].endAt) { 

         delete AuctionedNft[CollectionAddress];

         tokenIdExists[CollectionAddress];

      }

        emit startAuction(CollectionAddress, tokenId);
    }

    function bid(
        address CollectionAddress,
        uint256 tokenId,
        uint value
    )
        external 
        payable 
        auctionOngoing( CollectionAddress, tokenId)
        returns (bool)
        {
        require(AuctionedNft[CollectionAddress][tokenId].started, "not started");
        require(block.timestamp < AuctionedNft[CollectionAddress][tokenId].endAt, "ended");
        require(value > AuctionedNft[CollectionAddress][tokenId].highestBid, "value < highest");

        bidsTracker[msg.sender].set(value);

        AuctionedNft[CollectionAddress][tokenId].highestBid = value;
        AuctionedNft[CollectionAddress][tokenId].highestBidder = msg.sender;

        bidsTracker[msg.sender].set(value);
        emit Bid(msg.sender, value);
    }


    function acceptHighestBid(address collecton, uint tokenId){

        require(msg.sender = AuctionedNft[collecton][tokenId].Auctioner, "cant end  what ou didnt started");
        require(AuctionedNft[CollectionAddress][tokenId].started, "not started");
        require(block.timestamp < AuctionedNft[CollectionAddress][tokenId].endAt, "ended");

        delete  AuctionedNft[collecton][tokenId]
        IKRC20(collection[collection].collectionAddress).safeTransfer(AuctionedNft[collecton][tokenId].Auctioner, AuctionedNft[collecton][tokenId].highestBid);
        IERC721 nft = IERC721(collection);
        nft.safeTransferFrom(_msgSender(), AuctionedNft[collecton][tokenId].highestBidder, tokenId);
    }


    function addCollection(
        address _collection,
        address _collectionAddress,
        uint256 _royaltyFees
    ) external onlyOwner {
        require(
            !collectionAddresses.contains(_collection),
            "Collection already exists"
        );
        require(
            IERC721(_collection).supportsInterface(0x80ac58cd),
            "Collections's NFT Standards not supported"
        );
        require(
            _royaltyFees >= minFees && _royaltyFees <= (maxFees - tradeFee),
            "Royalty fees are exorbitant"
        );
        collectionAddresses.add(_collection);
        collection[_collection] = Collection(
            _collectionAddress,
            _royaltyFees,
        );
        emit CollectionAdded(_collection);
    }


}