// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pausable} from "./utils/Pausable.sol";

contract ERC20 is Pausable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );
    error ERC20InvalidReceiver(address recevier);
    error ERC20InvalidSender(address sender);
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );

    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);

    mapping(address account => uint256) private balances;
    mapping(address account => mapping(address spender => uint256))
        private _allowance;

    uint256 private totalSupply;
    string private name;
    string private symbol;
    address public controller;
    bool private _paused;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        controller = msg.sender;
        _mint(msg.sender, 100 ether);
    }

    function transfer(
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function pause() public {
        require(msg.sender == controller, "NO PERMISSION");
        _pause();
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowance[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    function _update(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            totalSupply += value;
        } else {
            uint256 fromBalance = balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                totalSupply -= value;
            }
        } else {
            unchecked {
                balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }
}
