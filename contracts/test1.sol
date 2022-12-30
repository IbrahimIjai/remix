
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract NowContract {
    uint32 public nowValue = 0;
    enum Name {item1, item2 }
    struct Data {
        uint num;
        Name name;
    }
    mapping (address => Data) public test;

    constructor ()  {
        computeNow();
    }

    function computeNow() public {
        nowValue = uint32(block.timestamp);
    }

    function passEnum(Name _r) public  {
        test[msg.sender]  = Data(1, _r);
    }
}