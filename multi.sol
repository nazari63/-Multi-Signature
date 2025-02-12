// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    address[] public owners;
    uint256 public requiredSignatures;
    mapping(address => bool) public isOwner;
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    struct Transaction {
        address to;
        uint256 amount;
        bool executed;
        uint256 signaturesCount;
        mapping(address => bool) signatures;
    }

    event TransactionCreated(uint256 indexed transactionId, address indexed to, uint256 amount);
    event TransactionSigned(uint256 indexed transactionId, address indexed signer);
    event TransactionExecuted(uint256 indexed transactionId, address indexed executor);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owner can call this");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactionId < transactionCount, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "Transaction already executed");
        _;
    }

    modifier notSigned(uint256 transactionId) {
        require(!transactions[transactionId].signatures[msg.sender], "Transaction already signed by you");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length > 0, "There must be at least one owner");
        require(_requiredSignatures > 0 && _requiredSignatures <= _owners.length, "Invalid number of required signatures");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            isOwner[owner] = true;
        }
        
        owners = _owners;
        requiredSignatures = _requiredSignatures;
    }

    function createTransaction(address to, uint256 amount) public onlyOwner {
        uint256 transactionId = transactionCount++;
        Transaction storage txn = transactions[transactionId];
        txn.to = to;
        txn.amount = amount;
        txn.executed = false;
        txn.signaturesCount = 0;

        emit TransactionCreated(transactionId, to, amount);
    }

    function signTransaction(uint256 transactionId) public onlyOwner transactionExists(transactionId) notExecuted(transactionId) notSigned(transactionId) {
        Transaction storage txn = transactions[transactionId];
        txn.signatures[msg.sender] = true;
        txn.signaturesCount++;

        emit TransactionSigned(transactionId, msg.sender);

        if (txn.signaturesCount >= requiredSignatures) {
            executeTransaction(transactionId);
        }
    }

    function executeTransaction(uint256 transactionId) internal transactionExists(transactionId) notExecuted(transactionId) {
        Transaction storage txn = transactions[transactionId];

        require(txn.signaturesCount >= requiredSignatures, "Not enough signatures");

        txn.executed = true;
        payable(txn.to).transfer(txn.amount);

        emit TransactionExecuted(transactionId, msg.sender);
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function getTransactionDetails(uint256 transactionId) public view returns (address to, uint256 amount, bool executed, uint256 signaturesCount) {
        Transaction storage txn = transactions[transactionId];
        return (txn.to, txn.amount, txn.executed, txn.signaturesCount);
    }

    // اضافه کردن موجودی به قرارداد
    receive() external payable {}
}