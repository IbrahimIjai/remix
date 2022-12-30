// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
interface IKRC20 is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUSDT {
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
interface IDAZ {
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

contract Amestarter is ReentrancyGuard {
    
    using SafeERC20 for IKRC20;

    address public immutable USDT;
    address private DAZ;
    uint public tokenPrice;
    address private owner;
    bool IDOStarted;
    bool claimStarted;
    uint256 targetSale;
    uint256 totalRaised;
    uint256 claimableTokens;


    //mappinng

    mapping(address => uint256) private purchase;

    //events
    event latestPurchased(
        address indexed buyer,
        uint amount
    );

    event icoUpdate(
        uint newTokenprice,
        uint256 target
    );
    event ICOStartAlert(
        string icoAlert
    );

    event claimToken(
        address buyuer,

        uint256 tokenBought
    );

    constructor(uint _tokenPrice, address _IUSDT, uint256 _targetSale){
        owner = msg.sender;
        tokenPrice = _tokenPrice * 10 ** 18;
        USDT = _IUSDT; 
        targetSale = _targetSale * 10 ** 18;
    }

    function purchaseToken(uint _amount)  public nonReentrant{
        require(IDOStarted == true, "IDO has not started");
        uint256 value = totalRaised + _amount;
        require(value < targetSale, "All tokens has been sold");
        IKRC20(USDT).safeTransferFrom(msg.sender, address(this), _amount);
        purchase[msg.sender]  += _amount;
        totalRaised += _amount;
        emit latestPurchased(msg.sender, _amount);
    }

    function startClaim(address _token, uint256 _tokens) external {
        require(msg.sender == owner, "Only owner can call this function");
        DAZ = _token;
        claimableTokens = _tokens;
        claimStarted = true;
    }

    function claimPurchasedToken() external nonReentrant {
        require(IDOStarted == false, "IDO Has  not ended, claim unavailable");
        require(purchase[msg.sender] > 0, "you did not participate");
        uint256  claimableAmount = purchase[msg.sender];
        uint256  token = (claimableAmount / tokenPrice);
        uint256 claimableToken = token * 10**18;
        purchase[msg.sender] = 0;
        IKRC20(DAZ).transferFrom(address(this), msg.sender, claimableToken);
        emit claimToken(msg.sender, token);
    }

    function claimRaisedFunds() external {
        require(msg.sender == owner, "Only owner can claim");
        uint256 raisedFunds = totalRaised;
        totalRaised = 0;
        IKRC20(USDT).transferFrom(address(this), msg.sender, raisedFunds);
    }

    function editIDO(uint _tokenPrice, uint256 _targetSale) public{
        require(msg.sender == owner);
        tokenPrice = _tokenPrice * 10 ** 18;
        targetSale = _targetSale * 10 ** 18;

        emit icoUpdate( _tokenPrice, _targetSale);
    }

    function BeginIDO() public {
        require(msg.sender == owner);
        IDOStarted = true;
        claimStarted = false;

        emit ICOStartAlert("ICO is on");
    }

    function StopIDO() public {
        require(msg.sender == owner);
        IDOStarted = false;
        emit ICOStartAlert("ICO is paused");
    }

    
}