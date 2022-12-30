// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

contract DistantFiAuction {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;
    using SafeERC20 for IKRC20;

    struct bids{
        address bidder;
        uint price;
    }
    struct auctionDetails {
        address seller;
        address nftCollectionAddress;
        uint tokenId;
        uint startTime;
        uint Duration;
        uint Currentprice;
        address highestBidder;
    }
    bids [] public biddersInfo;
    mapping(uint => auctionDetails) public AuctionedNFTs;
    mapping(address => EnumerableSet.UintSet) private AuctionCheck;
    mapping(uint => bids[] ) public bidders;

    function Auction (
        address _collectionAddress,
        uint _tokenId,
        uint _duration,//uint value in minutes eg, 2minutes
        uint curPrice,
        address _highestBidder
    ) external {
        uint realduration = _duration * 60;
        uint endTime = block.timestamp + realduration;
        AuctionedNFTs[block.timestamp] = 
                            auctionDetails(msg.sender, _collectionAddress,
                             _tokenId, block.timestamp, endTime, curPrice, _highestBidder);
        AuctionCheck[_collectionAddress].add(_tokenId);
    }
    function PlaceBid (
        uint _bidAmout,
        uint _auctionId 
    ) external  {
        bidders[_auctionId].push(bids(msg.sender, _bidAmout ));
        AuctionedNFTs[_auctionId].Currentprice  = _bidAmout;
        AuctionedNFTs[_auctionId].highestBidder = msg.sender;
    }

    function EndAuction (
        address _collectionAddress, 
        uint _tokenId,
        uint _auctionId
    ) external {
        IERC721 nft = IERC721(_collectionAddress);
        AuctionCheck[_collectionAddress].remove(_tokenId); 
        nft.safeTransferFrom(AuctionedNFTs[_auctionId].seller , AuctionedNFTs[_auctionId].highestBidder, _tokenId);
    }
}