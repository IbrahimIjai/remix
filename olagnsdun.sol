// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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

contract NFTMarketplace is Context, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;
    using SafeERC20 for IKRC20;

    address public immutable WKCS;
    uint8 public tradeFee;
    address private feeCollector;
    address private admin;
    uint8 public constant minFees = 0;
    uint8 public constant maxFees = 10;

    enum Status {
        Verified,
        Unverified
    }

    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 indexed price
    );
    event ItemUpdated(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed newPrice
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemDelisted(uint256 tokenId);
    event CollectionAdded(address collection);
    event CollectionUpdated(address collection);
    event CollectionUnverify(address collection);
    event CollectionRemoved(address collection);
    event OfferCreated(
        address indexed creator,
        address indexed owner,
        uint256 indexed value
    );
    event OfferUpdated(
        address indexed creator,
        address indexed owner,
        uint256 indexed value
    );
    event OfferCancelled(address creator, address collection, uint256 token);
    event OfferAccepted(
        address owner,
        address creator,
        address collection,
        uint256 token
    );
    event RevenueWithdrawn(address revenueCollector, uint256 revenue);
    event PlatformUpdated(
        uint256 fees,
        address indexed collector,
        address indexed admin
    );
    error PriceMustBeAboveZero(uint256 price);
    error NFTAlreadyListed(uint256 tokenId);

    constructor(
        uint8 _tradeFee,
        address _feeCollector,
        address _admin,
        address _WKCS
    ) {
        tradeFee = _tradeFee;
        feeCollector = _feeCollector;
        admin = _admin;
        WKCS = _WKCS;
        Ownable(_msgSender());
    }

    struct Listing {
        address seller;
        uint256 price;
    }
    struct Offer {
        address buyer;
        address seller;
        uint256 price;
        // address token;
    }
    struct Collection {
        address collectionAddress;
        uint256 royaltyFees;
        Status status;
    }

    mapping(address => mapping(uint256 => Listing)) public sellNFT;
    mapping(address => EnumerableSet.UintSet) private tokenIdExists;
    mapping(address => uint256) public revenue;
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private offerExists;
    mapping(address => Collection) public collection;
    mapping(address => mapping(uint256 => Offer)) public offer;

    modifier isAdmin() {
        _;
    }
    modifier isListed(address _collection, uint256 _tokenId) {
        require(
            tokenIdExists[_collection].contains(_tokenId),
            "NFT isn't listed for sale"
        );
        _;
    }
    modifier offerAvailable(
        address _collection,
        address _creator,
        uint256 _tokenId
    ) {
        require(
            offerExists[_collection][_creator].contains(_tokenId),
            "Offer doesn't exist"
        );
        _;
    }

    EnumerableSet.AddressSet private collectionAddresses;

    function list(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    ) external {
        IERC721 nft = IERC721(_collection);
        require(_msgSender() == nft.ownerOf(_tokenId), "msg.sender != owner");
        require(
            collectionAddresses.contains(_collection),
            "Collection is not listed"
        );
        if (tokenIdExists[_collection].contains(_tokenId)) {
            revert NFTAlreadyListed(_tokenId);
        }
        if (_price <= 0) {
            revert PriceMustBeAboveZero(_price);
        }
        sellNFT[_collection][_tokenId] = Listing(_msgSender(), _price);
        tokenIdExists[_collection].add(_tokenId);
        emit ItemListed(_msgSender(), _tokenId, _price);
    }

    function updateListing(
        address _collection,
        uint256 _tokenId,
        uint256 _newPrice
    ) external isListed(_collection, _tokenId) returns (bool) {
        IERC721 nft = IERC721(_collection);
        require(_msgSender() == nft.ownerOf(_tokenId), "msg.sender != owner");
        sellNFT[_collection][_tokenId].price = _newPrice;
        emit ItemUpdated(_msgSender(), _tokenId, _newPrice);
        return true;
    }

    function cancelListing(address _collection, uint256 _tokenId)
        external
        isListed(_collection, _tokenId)
        nonReentrant
    {
        IERC721 nft = IERC721(_collection);
        require(_msgSender() == nft.ownerOf(_tokenId), "msg.sender != owner");
        delete (sellNFT[_collection][_tokenId]);
        tokenIdExists[_collection].remove(_tokenId);
        emit ItemDelisted(_tokenId);
    }

    function buyNFT(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    )
        external
        // payable
        isListed(_collection, _tokenId)
        nonReentrant
    {
        IERC721 nft = IERC721(_collection);
        require(
            nft.getApproved(_tokenId) == address(this),
            "MacKett isn't approved to sell this NFT"
        );
        require(
            _price == sellNFT[_collection][_tokenId].price,
            "Price mismatch"
        );
        // IWKCS(WKCS).deposit{value: msg.value}();
        IKRC20(WKCS).safeTransferFrom(
            address(msg.sender),
            address(this),
            _price
        );
        _buyNFT(_collection, _tokenId, _price);
    }

    function _buyNFT(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    ) internal {
        Listing memory listing = sellNFT[_collection][_tokenId];
        IERC721 nft = IERC721(_collection);
        (uint256 amount, uint256 marketplaceFee, uint256 collectionFee) = _fees(
            _collection,
            _price
        );
        delete (sellNFT[_collection][_tokenId]);
        tokenIdExists[_collection].remove(_tokenId);
        if (collectionFee != 0) {
            revenue[collection[_collection].collectionAddress] += collectionFee;
        }
        if (marketplaceFee != 0) {
            revenue[feeCollector] += marketplaceFee;
        }
        address seller = listing.seller;
        // IKRC20(WKCS).safeTransfer(seller, amount);
        // (bool success, ) = seller.call{value: amount}("");
        // require(success, "Transaction reverted");
        IKRC20(WKCS).safeTransfer(seller, amount);
        nft.safeTransferFrom(seller, _msgSender(), _tokenId);
        emit ItemSold(listing.seller, _msgSender(), _tokenId, _price);
    }

    function _fees(address _collection, uint256 _price)
        internal
        view
        returns (
            uint256 amount,
            uint256 marketplaceFee,
            uint256 collectionFee
        )
    {
        marketplaceFee = (_price * tradeFee) / 100;
        collectionFee = (_price * collection[_collection].royaltyFees) / 100;
        amount = _price - (marketplaceFee + collectionFee);
        return (amount, marketplaceFee, collectionFee);
    }

    function addCollection(
        address _collection,
        address _collectionAddress,
        uint256 _royaltyFees
    ) external isAdmin {
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
            Status.Unverified
        );
        emit CollectionAdded(_collection);
    }

    function updateCollection(
        address _collection,
        address _collectionAddress,
        uint256 _royaltyFees
    ) external isAdmin {
        require(
            collectionAddresses.contains(_collection),
            "Collection isn't listed, can't verify"
        );
        require(
            _royaltyFees >= minFees && _royaltyFees <= (maxFees - tradeFee),
            "Royalty fees are exorbitant"
        );
        collection[_collection] = Collection(
            _collectionAddress,
            _royaltyFees,
            Status.Verified
        );
        emit CollectionUpdated(_collection);
    }

    function unverifyCollection(address _collection) external isAdmin {
        require(
            collectionAddresses.contains(_collection),
            "Collection isn't listed, can't verify"
        );
        Collection storage collectionStatus = collection[_collection];
        collectionStatus.status = Status.Unverified;
        emit CollectionUnverify(_collection);
    }

    function createOffer(
        address _collection,
        uint256 _tokenId,
        uint256 _value
    )
        external
        // address _WKCS
        isListed(_collection, _tokenId)
        nonReentrant
        returns (bool)
    {
        require(
            !offerExists[_collection][_msgSender()].contains(_tokenId),
            "Offer already exists. Update instead"
        );
        IERC721 nft = IERC721(_collection);
        address itemOwner = nft.ownerOf(_tokenId);
        offer[_collection][_tokenId] = Offer(_msgSender(), itemOwner, _value);
        offerExists[_collection][_msgSender()].add(_tokenId);
        emit OfferCreated(_msgSender(), itemOwner, _value);
        return true;
    }

    function updateOffer(
        address _collection,
        uint256 _tokenId,
        uint256 _newValue
    )
        external
        isListed(_collection, _tokenId)
        nonReentrant
        offerAvailable(_collection, _msgSender(), _tokenId)
        returns (bool)
    {
        Offer storage changeOffer = offer[_collection][_tokenId];
        IERC721 nft = IERC721(_collection);
        address itemOwner = nft.ownerOf(_tokenId);
        changeOffer.price = _newValue;
        emit OfferUpdated(_msgSender(), itemOwner, _newValue);
        return true;
    }

    function cancelOffer(address _collection, uint256 _tokenId)
        external
        nonReentrant
        offerAvailable(_collection, _msgSender(), _tokenId)
    {
        delete (offer[_collection][_tokenId]);
        offerExists[_collection][_msgSender()].remove(_tokenId);
        emit OfferCancelled(_msgSender(), _collection, _tokenId);
    }

    function acceptOffer(address _collection, uint256 _tokenId)
        external
        nonReentrant
    {
        Offer memory offerDetail = offer[_collection][_tokenId];
        require(offerExists[_collection][offerDetail.buyer].contains(_tokenId));
        IERC721 nft = IERC721(_collection);
        require(
            nft.ownerOf(_tokenId) == _msgSender(),
            "You don't own access to execute this function"
        );
        IKRC20(WKCS).safeTransferFrom(
            offerDetail.buyer,
            address(this),
            offerDetail.price
        );
        _acceptOffer(_collection, _tokenId, offerDetail.price);
    }

    function _acceptOffer(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    ) internal {
        Offer storage offerDetails = offer[_collection][_tokenId];
        IERC721 nft = IERC721(_collection);
        address buyer = offerDetails.buyer;
        (uint256 amount, uint256 marketplaceFee, uint256 collectionFee) = _fees(
            _collection,
            _price
        );
        if (collectionFee != 0) {
            revenue[collection[_collection].collectionAddress] += collectionFee;
        }
        if (tradeFee != 0) {
            revenue[feeCollector] += marketplaceFee;
        }
        delete (offer[_collection][_tokenId]);
        offerExists[_collection][buyer].remove(_tokenId);
        //payable(_msgSender()).call{value: amount}("");
        // IKRC20(WKCS).safeTransferFrom(buyer, _msgSender(), amount);
        IKRC20(WKCS).safeTransfer(_msgSender(), amount);
        nft.safeTransferFrom(_msgSender(), buyer, _tokenId);
        emit OfferAccepted(_msgSender(), buyer, _collection, _tokenId);
        emit OfferCancelled(buyer, _collection, _tokenId);
    }

    function withdrawRevenue() external nonReentrant {
        uint256 revenueGenerated = revenue[_msgSender()];
        require(revenueGenerated != 0, "Nothing to claim");
        revenue[_msgSender()] = 0;
        // (bool success, ) = _msgSender().call{value: revenueGenerated}("");
        // require(success, "Transaction reverted");
        IKRC20(WKCS).safeTransfer(_msgSender(), revenueGenerated);
        emit RevenueWithdrawn(_msgSender(), revenueGenerated);
    }

    function updatePlatform(
        uint8 _newTradeFees,
        address _newFeeCollector,
        address _newAdmin
    ) external onlyOwner {
        tradeFee = _newTradeFees;
        feeCollector = _newFeeCollector;
        admin = _newAdmin;
        emit PlatformUpdated(_newTradeFees, _newFeeCollector, _newAdmin);
    }
}
