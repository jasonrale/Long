// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * Go🐉Long🐉To The Moon!!!
 */
interface Long {
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function setTransferable(bool isTransferable) external;
    function burn(uint256 value) external returns (bool);
}

interface IPancakeRouter01 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract LongInscriber {
    bool public isShutdown;
    uint256 public totalDroped;

    address public owner;
    address public LONG;
    address private constant panckeRouterAddress = 0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb;

    uint256 private constant _signal = 2500;
    uint256 private constant _mintable = 12500000;
    uint256 private constant _value = 0.00025 * 10**18;
    uint256 private constant _singleAmount = 1 * 10 ** 18; 
    uint256 private constant _deployAmount = 1700 * 10 ** 18;
    uint256 private constant _poolAmount = 8500000 * 10 ** 18; 
    uint256 private constant _mintableAmount = 12500000 * 10 ** 18;
    
    constructor(address _long) {
        owner = msg.sender;
        LONG = _long;
    }

    function approvePancake() external {
        require(msg.sender == owner, "Not owner");
        Long long = Long(LONG);
        long.approve(panckeRouterAddress, _poolAmount);
    }

    function shutdowm() external {
        require(msg.sender == owner, "Not owner");
        require(!isShutdown, "Already shutdown");

        Long long = Long(LONG);
        long.burn(long.balanceOf(address(this)));
        long.setTransferable(true);
        isShutdown = true;
    }

    function _deployLiquidity(uint256 _amount) internal {
        uint256 deadLine = block.timestamp + 180;
        uint256 balance = address(this).balance;
        IPancakeRouter01(panckeRouterAddress).addLiquidityETH{value:balance}(LONG, _amount, _amount, balance, address(0), deadLine);
    }

    function inscribe() internal {
        address _msgSender = msg.sender;
        require(_msgSender == tx.origin, "Only EOA");
        require(msg.value == _value, "Incorrect value");
        require(!isShutdown, "Already shutdown");

        ++totalDroped;

        Long long = Long(LONG);
        if (totalDroped % _signal == 0) {
            _deployLiquidity(_deployAmount);
        }
        if (totalDroped == _mintable) {
            long.setTransferable(true);
        }

        require(long.balanceOf(address(this)) >= _singleAmount, "Inscribed out");
        require(long.transfer(_msgSender, _singleAmount), "Transfer failed");
    }

    receive() external payable {
        inscribe();
    }
}
