// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    error ERC20InsufficientAmount(
        address sender,
        uint256 amount,
        uint256 needed
    );

    error ERC20InvalidAddress(address addr);
    error ERC2612ExpireedSignature(uint256 deadline);

    mapping(address => uint256) private balances;
    mapping(address => uint256) private _nonces;
    mapping(address => mapping(address => uint256)) private _allowance;
    uint256 private totalSupply;
    address private controller;
    bool private _paused;
    string private name;
    string private symbol;
    bytes32 private immutable _cachedDomainSeparator;

    /**keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");*/
    bytes32 private constant TYPE_HASH =
        0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;
    /**keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");*/
    bytes32 private constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    modifier whenNotPaused() {
        if (_paused) {
            revert("PAUSED");
        }
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        controller = msg.sender;
        _update(address(0), msg.sender, 100 ether);
        _cachedDomainSeparator = keccak256(
            abi.encode(TYPE_HASH, block.chainid, address(this))
        );
    }

    function transfer(
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value, true);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    function pause() external {
        require(msg.sender == controller, "NO PERMISSION");
        _paused = !_paused;
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

        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "INVALID_SIGNER");
        require(signer != address(0));

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

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidAddress(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidAddress(address(0));
        }

        _update(from, to, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal {
        if (owner == address(0) || spender == address(0)) {
            revert ERC20InvalidAddress(address(0));
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
                revert ERC20InsufficientAmount(
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
                revert ERC20InsufficientAmount(from, fromBalance, value);
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
