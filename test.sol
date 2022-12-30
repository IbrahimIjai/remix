//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Transactions {

    //Address --> Contract -- deposit
    function calc(uint val, uint val2) public pure returns (uint) {
        uint newVal = val/val2;
        return newVal * 10 ** 18;
    }
}