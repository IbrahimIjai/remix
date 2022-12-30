// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract usdt  {
    using SafeMath for uint;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
     // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;
    string public name;
    // "Crypto for us test";
    string  public symbol;
    // "C4U";
    address public _owner;
    uint   public _decimals;


    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);




    constructor(string memory _name, string memory _symbol){
         _owner = msg.sender;
          _name = name;
          _symbol = symbol;
          _decimals = 18;
    }
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
     /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

     /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            _owner = newOwner;
        }
    }
    
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[_owner] = balances[_owner].add(fee);
            emit Transfer(msg.sender, _owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    //  /**
    // * @dev Gets the balance of the specified address.
    // * @param _owner The address to query the the balance of.
    // * @return An uint representing the amount owned by the passed address.
    // */
            function owner() public view returns (address) {
                return _owner;
            }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowance[_from][msg.sender]);
        // add the balance for transferFrom
        balances[_to] += _value;
        // subtract the balance for transferFrom
        balances[_from] -= _value;
        allowance[msg.sender][_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // function _owner() public view returns (uint){

    // }

}


