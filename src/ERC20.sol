// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pausable} from "./utils/Pausable.sol";
import {ECDSA} from "./utils/ECDSA.sol";
import "forge-std/console.sol";

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
    error InvalidAccountNonce(address account, uint256 currentNonce);
    error ERC2612ExpireedSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);

    mapping(address account => uint256) private balances;
    mapping(address account => uint256) private _nonces;
    mapping(address account => mapping(address spender => uint256))
        private _allowance;

    string private name;
    string private symbol;
    uint256 private totalSupply;
    address public controller;
    bool private _paused;
    bytes32 private immutable _hashedName;
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;
    bytes32 private constant TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        controller = msg.sender;
        _mint(msg.sender, 100 ether);
        _cachedChainId = block.chainid;
        _cachedDomainSeparator = keccak256(
            abi.encode(TYPE_HASH, _hashedName, block.chainid, address(this))
        ); //_buildDomainSeparator();
        _cachedThis = address(this);
        _hashedName = keccak256(bytes(_name));
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
        _approve(owner, spender, value, true);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    function pause() public {
        require(msg.sender == controller, "NO PERMISSION");
        _pause();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (block.timestamp > deadline) {
            revert ERC2612ExpireedSignature(deadline);
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = _toTypedDataHash(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert("INVALID_SIGNER");
        }

        _approve(owner, spender, value, true);
    }

    function _toTypedDataHash(
        bytes32 structHash
    ) public view returns (bytes32 digest) {
        bytes32 domainSeparator = _cachedDomainSeparator;

        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(TYPE_HASH, _hashedName, block.chainid, address(this))
            );
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
