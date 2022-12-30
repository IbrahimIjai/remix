pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tether is ERC20{
    constructor(uint256 _supply) ERC20("Tether USD", "USDT") {
        _mint(msg.sender, _supply * (10**decimals()));
    }
}