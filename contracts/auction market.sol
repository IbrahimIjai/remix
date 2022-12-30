// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auctionn {

    address payable public auctioner;
    uint public start_block;
    uint public end_block;
    enum Auction_State {started,  Running,  finished, Cancelled}
    Auction_State public auctionState;

    uint public highest_bid;
    uint public highest_payable_bid;
    uint public bidInc;

    address payable public  highestBidder;
    mapping (address => uint) public bids;

    constructor(){
        auctioner = payable(msg.sender);
        auctionState = Auction_State.Running;
        start_block = block.number;
        end_block = start_block + 240;
        bidInc = 1 ether;
    }

    modifier notOwner(){
        require(msg.sender != auctioner, "owner cannot bid");
        _;
    }

     modifier Owner(){
        require(msg.sender == auctioner, "owner cannot bid");
        _;
    }

    modifier started(){
        require(block.number>start_block);
        _;
    }

    modifier ended(){
        require(block.number<end_block);
        _;
    }

    modifier beforeFunding(){
        require(block.number<end_block);
        _;
    }

    function cancelAuc() public Owner{
        auctionState = Auction_State.Cancelled;

    }

    function min(uint a, uint b) pure private returns (uint){
        if(a<=b)
        return a;
        else return b;
    }

    function Bid() payable public notOwner started {

        require(auctionState = Auction_State.Running);
        require(msg.value>1 ether);

        uint currentBid = bids[msg.sender] + msg.value;

        require (currentBid>highest_payable_bid);
        bids[msg.sender] = currentBid;

        if(currentBid<bids[highestBidder]){
            highest_payable_bid = min(currentBid+bidInc, bids[highest_bid]);
        } else {
            highest_payable_bid = min(currentBid,bids[highestBidder]+bidInc);
            highestBidder = payable (msg.sender);

        }
    }

    function finalizeAuc() public{
        require(auctionState == Auction_State.Cancelled);
        require(msg.sender == auctioner||bids[msg.sender]>0);
        

        address payable person;
        uint value;

        if(auctionState == Auction_State.Cancelled){
            person = payable(msg.sender);
            value - bids[msg.sender];
        }else{
            if(msg.sender==auctioner){
                person = auctioner;
                value = bids[highestBidder]-highest_payable_bid;

            }else{
                person = payable (msg.sender);
                value = bids[msg.sender];
            }
        }
    }
    bids[msg.senderr]=0;
    person.transfer(value);

}