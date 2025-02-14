// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

contract Test {
    string private name;
    string private symbol;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _cachedDomainSeparator;
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
        _cachedDomainSeparator = keccak256(
            abi.encode(TYPE_HASH, _hashedName, block.chainid, address(this))
        );

        //_cachedDomainSeparator=_buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(TYPE_HASH, _hashedName, block.chainid, address(this))
            );
    }
}
