// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );
    error ERC20InvalidReceiver(address recevier);

    mapping(address account => uint256) private balances;
    mapping(address account => mapping(address spender => uint256))
        private allowance;

    uint256 private totalSupply;
    string private name;
    string private symbol;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _mint(msg.sender, 100 ether);
    }

    function transfer(address to, address value) public returns (bool) {
        address = owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
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
