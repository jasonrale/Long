// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Fair {
    string private _name = "待定";
    string private _symbol = "待定";
    uint8 private _decimals = 18;
    uint256 private _taxRate;
    uint256 private _totalSupply;

    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    mapping(address => bool) private _tempList; // Only For FairDrop Contract.

    address private _admin;
    address private _vault;
    bool private _isTransferable;   // Enable after droping is completed.

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    error ERC20InvalidSender(address sender);

    error ERC20InvalidReceiver(address receiver);

    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    error ERC20InvalidApprover(address approver);

    error ERC20InvalidSpender(address spender);

    error TransferNotStart();

    constructor(address vault, uint8 rate) {
        _admin = msg.sender;
        _vault = vault;
        _taxRate = rate;
        _mint(msg.sender, 待定 * 10 ** 18);
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "Not admin");
        _;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function taxRate() public view returns (uint256) {
        return _taxRate;
    }

    function transferable() external view returns (bool) {
        return _isTransferable;
    }

    function admin() external view returns (address) {
        return _admin;
    }

    // After droping is completed, will be transfered to Black Hole.
    function transferAdmin(address adminAddress) external onlyAdmin() {
        _admin = adminAddress;
    }

    // After droping is completed.(Only can enable)
    function _enableTransfer() external onlyAdmin {
        _isTransferable = true;
    }

    function setVault(address vault) external onlyAdmin {
        _vault = vault;
    }

    function setTaxRate(uint8 rate) external onlyAdmin {
        require(rate <= 100, "Tax rate overflow");
        _taxRate = rate;
    }

    function updateTempList(address account, bool isTemp) external onlyAdmin {
        _tempList[account] = isTemp;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        if (_isTransferable || _tempList[from]) {
            if (_taxRate == 0 || _tempList[from]) {
                _update(from, to, value);
            } else {
                uint256 taxAmount = value * _taxRate / 100;
                _update(from, to, value - taxAmount);
                _update(from, _vault, taxAmount);
            }
        } else {
            revert TransferNotStart();
        }
    }

    function _update(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    // _mint only occurs once during initialization.
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function burn(uint256 value) external returns (bool) {
        address burner = _msgSender();
        require(balanceOf(burner) >= value, "Insufficient balance");
        _burn(burner, value);
        return true;
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}
