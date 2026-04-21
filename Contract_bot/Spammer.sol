// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

library UniswapV2Library {
    using SafeMath for uint256;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            )
        );
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

library TransferHelper {
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

error NotAllowed();
error CouldNotBuy();
error TransferFailed();

contract OptimizedSpammerv1_1 {
    using SafeMath for uint256;

    mapping(address => bool) private guests;
    address payable immutable owner;

    address private constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private constant UNISWAP_ROUTER_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    constructor() {
        owner = payable(0x7B57f3d0C21495B5A9DdBa39d06a38eeD4939582);
        guests[msg.sender] = true;
    }

    function checkUser(address user) internal view {
        if (user != owner && !guests[user]) revert NotAllowed();
    }

    function addGuest(address guest, bool permission) external {
        checkUser(msg.sender);
        guests[guest] = permission;
    }

    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        uint256 pathLen = path.length;
        for (uint256 i; i < pathLen - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < pathLen - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal {
        uint256 pathLen = path.length;
        for (uint256 i; i < pathLen - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < pathLen - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function BuyMany(
        uint256 maxTx,
        address[] calldata path,
        address[] calldata recipients,
        uint256 tip
    ) external payable {
        checkUser(msg.sender);
        {
            (uint256 r0, uint256 r1) = UniswapV2Library.getReserves(factory, path[0], path[1]);
            if (r0 == 0 || r1 == 0) revert CouldNotBuy();
        }
        uint256 ethForBuys = msg.value - tip;
        IWETH(WETH).deposit{value: ethForBuys}();
        uint256 count = recipients.length;
        uint256 ethValForEach = ethForBuys / count;
        for (uint256 i; i < count;) {
            uint256[] memory buyAmounts = UniswapV2Library.getAmountsIn(factory, maxTx, path);
            if (ethValForEach >= buyAmounts[0]) {
                assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), buyAmounts[0]));
                _swap(buyAmounts, path, recipients[i]);
            } else {
                if (i == 0) revert CouldNotBuy();
                break;
            }
            unchecked { ++i; }
        }
        (bool ok,) = block.coinbase.call{value: tip}("");
        require(ok);
        IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        (bool ok2,) = payable(msg.sender).call{value: address(this).balance}("");
        require(ok2);
    }

    function _flatBuyOne(
        uint256 minTokens,
        uint256 maxTx,
        address[] calldata path,
        address recipient,
        uint256 ethAmountForEach,
        bool buyExact
    ) private returns (bool) {
        uint256[] memory buyAmounts = UniswapV2Library.getAmountsIn(factory, minTokens, path);
        if (ethAmountForEach < buyAmounts[0]) return false;
        address pair = UniswapV2Library.pairFor(factory, path[0], path[1]);
        if (buyExact) {
            uint256[] memory exactAmounts = UniswapV2Library.getAmountsIn(factory, maxTx, path);
            assert(IWETH(WETH).transfer(pair, exactAmounts[0]));
            _swap(exactAmounts, path, recipient);
        } else {
            assert(IWETH(WETH).transfer(pair, ethAmountForEach));
            uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(recipient);
            _swapSupportingFeeOnTransferTokens(path, recipient);
            require(
                IERC20(path[path.length - 1]).balanceOf(recipient).sub(balanceBefore) >= minTokens,
                "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
            );
        }
        return true;
    }

    function BuyManyFlat(
        uint256 minTokens,
        uint256 maxTx,
        address[] calldata path,
        address[] calldata recipients,
        uint256 tip
    ) external payable {
        checkUser(msg.sender);
        {
            (uint256 r0, uint256 r1) = UniswapV2Library.getReserves(factory, path[0], path[1]);
            if (r0 == 0 || r1 == 0) revert CouldNotBuy();
        }
        uint256 ethForBuys = msg.value - tip;
        IWETH(WETH).deposit{value: ethForBuys}();
        uint256 count = recipients.length;
        uint256 ethAmountForEach = ethForBuys / count;
        bool buyExact = minTokens > maxTx;
        for (uint256 i; i < count;) {
            if (!_flatBuyOne(minTokens, maxTx, path, recipients[i], ethAmountForEach, buyExact)) {
                if (i == 0) revert CouldNotBuy();
                break;
            }
            unchecked { ++i; }
        }
        (bool ok,) = block.coinbase.call{value: tip}("");
        require(ok);
        IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        (bool ok2,) = payable(msg.sender).call{value: address(this).balance}("");
        require(ok2);
    }

    function giveBack() external {
        if (msg.sender != owner) revert NotAllowed();
        IERC20(WETH).transfer(owner, IERC20(WETH).balanceOf(address(this)));
    }

    function checkAddress() view external {
        checkUser(msg.sender);
    }

    receive() external payable {}
    fallback() external payable {}
}
