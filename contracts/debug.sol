 pragma solidity ^0.5.16;

 contract test{

      struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint numConfirmations;
    }

    //  Transaction[] public transactions;
     mapping(uint => Transaction) transactions;
     uint numTrans;

     function submitTransaction(address _to, uint _value, bytes memory _data)
        public
        onlyOwner {

            Transaction storage r = transactions[numTrans++];
            uint txIndex = transactions.length;
            r.to: _to,
            r.value: _value,
            r.data: _data,
            r.executed: false,
            r.numConfirmations: 0
            
            emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
            
        }    
    
           
        

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    

 }
 
 