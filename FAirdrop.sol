// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface Fair {
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
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

contract FAirdrop {
    address public owner;
    address public FAIR;
    address public constant panckeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    bool public isShutdown;
    uint256 public tokenId;
    uint256 public totalDroped;
    uint256 public threshold;

    uint256 private constant _value = 0.002 * 10**18;
    uint256 private constant _singleAmount = 100000000 * 10 ** 18; 
    uint256 private constant _deployAmount = 40000000 * 10 ** 18;
    uint256 private constant _poolAmount = 6000000000000 * 10 ** 18; 
    uint256 private constant _mintableAmount = 15000000000000 * 10 ** 18;
    
    constructor(address _fair) {
        owner = msg.sender;
        FAIR = _fair;
        totalDroped = 0;
    }

    function approvePancake() external {
        require(msg.sender == owner, "Not owner");
        Fair fair = Fair(FAIR);
        fair.approve(panckeRouterAddress, _poolAmount);
    }

    function shutdowm() external {
        require(msg.sender == owner, "Not owner");
        require(!isShutdown, "Already shutdown");

        Fair fair = Fair(FAIR);
        fair.burn(fair.balanceOf(address(this)));
        isShutdown = true;
    }

    function _deployLiquidity(uint256 _amount) internal {
        uint256 deadLine = block.timestamp + 180;
        uint256 balance = address(this).balance;
        IPancakeRouter01(panckeRouterAddress).addLiquidityETH{value:balance}(FAIR, _amount, _amount, balance, address(0), deadLine);
        threshold = 0;
    }

    function fAirdrop() internal {
        address _msgSender = msg.sender;
        require(_msgSender == tx.origin, "Only EOA");
        require(msg.value == _value, "Incorrect value");
        require(!isShutdown, "Already shutdown");

        ++totalDroped;
        ++threshold;
        if (totalDroped == 1 || totalDroped % 300 == 0) {
            _deployLiquidity(_deployAmount * threshold);
        }

        Fair fair = Fair(FAIR);
        require(fair.balanceOf(address(this)) >= _singleAmount, "Droped out");
        require(fair.transfer(_msgSender, _singleAmount), "Transfer failed");
    }

    receive() external payable {
        fAirdrop();
    }
}