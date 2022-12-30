// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Staking {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate = 100;
    uint public lastUpdateTime;
    uint public rewardPerTokenStore;
    address owner;
    mapping (address => uint ) public userRewardPerTokenPaid;
    mapping (address => uint ) public rewards;
    uint private  TotalSupply;
    mapping ( address => uint) public _balances;

    constructor(
    address _rewardsToken,
    address _stakingToken
    )  {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        owner = msg.sender;
    }

    modifier updateReward(address account) {
        rewardPerTokenStore = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[account] = earned(account);
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStore;
        }
        _;
    }

    function earned(address account) public view returns(uint){
        return (
            _balances[account] * (rewardPerToken()- userRewardPerTokenPaid[account])/1e18
        )+ rewards[account];
    }

    function rewardPerToken() public view returns (uint) {
        if (TotalSupply == 0){
            return 0;
        }
        return rewardPerTokenStore + (
            rewardRate * (block.timestamp - lastUpdateTime) * 1e18 / TotalSupply
        );
    }

    function stake (uint _amount) external{
        TotalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender , address(this), _amount);
    }

    function withdraww (uint _amount) external{
        TotalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender , _amount);
    }

    function getReward() external {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
    //    function earned(address account) public view returns (uint256) {
    //     return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    // }

    // function lastTimeRewardApplicable() public view returns (uint256) {
    //     return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    // }

    // function rewardPerToken() public view returns (uint256) {
    //     if (_totalSupply == 0) {
    //         return rewardPerTokenStore;
    //     }
    //     return
    //         rewardPerTokenStore.add(
    //             lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(TotalSupply)
    //         );
    // }

    
}