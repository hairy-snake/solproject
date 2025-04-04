// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MultiSigWallet is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address[] public owners;
    uint256 public required;
    uint256 public transactionsCount;

    struct Tx {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
        mapping(address => bool) confirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(uint256 => address) public txs;

    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(
        address indexed sender,
        uint256 indexed transactionId,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(
        address indexed sender,
        uint256 indexed transactionId
    );
    event ExecuteTransaction(
        address indexed sender,
        uint256 indexed transactionId
    );

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }

    function isOwner(address _owner) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                return true;
            }
        }
        return false;
    }

    function initialize(
        address[] memory _owners,
        uint256 _required
    ) public initializer {
        require(_owners.length > 0, "Owners array cannot be empty");
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid required number"
        );
        owners = _owners;
        required = _required;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function confirmTransaction(uint256 _transactionId) public onlyOwner {
        Tx storage t = txs[_transactionId];
        require(!t.executed, "Transaction already executed");
        require(!t.confirmations[msg.sender], "Transaction already confirmed");

        t.confirmations[msg.sender] = true;
        t.numConfirmations++;

        emit ConfirmTransaction(msg.sender, _transactionId);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner returns (uint256) {
        txs[transactionsCount] = Tx({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        });
        transactionsCount++;

        emit SubmitTransaction(
            msg.sender,
            transactionsCount - 1,
            _to,
            _value,
            _data
        );

        return transactionsCount - 1;
    }

    function executeTransaction(uint256 _transactionId) public onlyOwner {
        Tx storage t = txs[_transactionId];
        require(!t.executed, "Transaction already executed");
        require(t.numConfirmations >= required, "Not enough confirmations");

        t.executed = true;

        (bool success, bytes memory result) = t.to.call{value: t.value}(t.data);
        require(success, string(result));

        emit ExecuteTransaction(msg.sender, _transactionId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
