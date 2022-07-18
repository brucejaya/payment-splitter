// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract MultiSig {
    
    ////////////////
    // KEYS
    ////////////////

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
	
	// ! duplicate
	
	function addressToKey(
        address account
    )
        public 
        view 
    {
        return keccak256(abi.encode(account));
    }


    ////////////////
    // KEYS
    ////////////////
    uint256 constant MANAGEMENT_KEY = 1;
    uint256 constant ACTION_KEY = 2;
    uint256 constant CLAIM_SIGNER_KEY = 3;
    uint256 constant ENCRYPTION_KEY = 4;
    
    mapping(uint256 => bytes32[]) internal _keysByPurpose;
    mapping(bytes32 => Key) internal _keys;

    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
		bool exists; // TODO 
    }

    ////////////////
    // EXEUCTIONS
    ////////////////

    mapping(uint256 => Transaction) internal _transactions;
    uint256 internal _transactionNonce;
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bytes32[] approved;
        bool executed;
    }

    ////////////////
    // MULTI-SIG
    ////////////////

    // @dev Mapping from OP type to number of approval required
    mapping(uint256 => uint256) internal _sigRequirements;

	// @dev Mapping from transactionId to bytes array
	mapping(uint256 => bytes32[]) public _sigConfirmations;
	// ! Design patter such that checks _sigConfirmations[id].length

	// mapping (uint256 => mapping (bytes32 => bool)) public _sigConfirmations;
	
    ////////////////
    // MODIFIERS
    ////////////////
	
    modifier onlyWallet() {
        require(_msgSender() == address(this));
        _;
    }

    modifier keyExists() {
        require(_keys[addressToKey(_msgSender())].exists, "Key does not exist on account");
        _;
    }

    modifier keyDoesNotExist() {
        require(!_keys[addressToKey(_msgSender())].exists);
        _;
    }


    modifier transactionExists(
		uint256 transactionId
	) {
        require(_transactions[transactionId].to != 0);
        _;
    }

	// Think this checks the caller is an approver 
    modifier approved(
		uint256 transactionId
	) {
		// TODO check this
        require(_sigConfirmations[transactionId][addressToKey(_msgSender())]);
        _;
    }

	// Think this checks the caller is an has not approved
    modifier notApproved(
		uint256 transactionId
	) {
		// TODO check this
        require(!_sigConfirmations[transactionId][addressToKey(_msgSender())]);
        _;
    }

    modifier notExecuted(
		uint256 transactionId
	) {
        require(!_transactions[transactionId].executed);
        _;
    }

    modifier notNull(
		address _address
	) {
        require(_address != 0);
        _;
    }
	
    modifier validRequirement(
		uint256 operationType,
		uint256 required
	) {
        require(required != 0, "Can't set the number of keys required to zero!");
		require(required < _keys.length, "Number of keys required cannot exceed or match key count");
        _;
    }





	// @dev Allows to change the number of required _sigConfirmations. Transaction has to be sent by wallet.
    function changeRequirements(
		uint256 operationType,
		uint256 required
	)
        public
        onlyWallet
        validRequirement(operationType, required)
    {
		_sigRequirements[operationType] = required;
        RequirementChange(operationType, required);
    }

    // @dev Allows an key to submit and approved a transaction.
    function submitTransaction(
		address to,
		uint256 value,
		bytes data
	)
        public
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(to, value, data);
        approveTransaction(transactionId);
    }

    // @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    function addTransaction(
		address to,
		uint256 value,
		bytes data
	)
        internal
        notNull(to)
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        _transactions[transactionId] = Transaction({
            to: to,
            value: value,
            data: data,
            approved: false,
            executed: false
        });
        transactionCount += 1;
        // emit Submission(transactionId);
    }

    // @dev Allows an key to approved a transaction.
    function approveTransaction(
		uint256 transactionId
	)
        public
        keyExists
        transactionExists(transactionId)
        notApproved(transactionId, _msgSender())
    {
		_transactions[transactionId].approved.append(addressToKey(_msgSender()));
        // emit Confirmation(_msgSender(), transactionId);
        executeTransaction(transactionId);
    }

    // @dev Allows anyone to execute a approved transaction.
    function executeTransaction(
		uint256 transactionId
	)
        public
        keyExists
        approved(transactionId, _msgSender())
        notExecuted(transactionId)
    {
        if (isApproved(transactionId, ACTION_KEY)) {
            (success,) = _transactions[transactionId].to.call{value:(_transactions[transactionId].value)}(abi.encode(_transactions[transactionId].data, 0));
            if (success) {
                _transactions[transactionId].executed = true;
                emit Executed(transactionId, _transactions[transactionId].to, _transactions[transactionId].value, _transactions[transactionId].data);
                return true;
            } else {
                emit TransactionFailed(transactionId, _transactions[transactionId].to, _transactions[transactionId].value, _transactions[transactionId].data);
                return false;
            }
        }
    }

    // @dev Returns the approval status of a transaction.
    function isApproved(
		uint256 transactionId,
		uint256 operationType
	)
        public
		view
        returns (bool)
    {
		if (getConfirmationCount(transactionId) == _sigRequirements[operationType]) {
			return true;
		}
		else {
			return false;
		}
    }

    // @dev Allows an key to revoke a approval for a transaction.
    function revokeConfirmation(
		uint256 transactionId
	)
        public
        keyExists
        approved(transactionId)
        notExecuted(transactionId)
    {
		delete _transactions[transactionId].approved[_msgSender()];
        // emit Revocation(_msgSender(), transactionId);
    }

    // @dev Returns number of confirmations of a transaction.
    function getConfirmationCount(
		uint256 transactionId
	)
        public
		view
        returns (uint256 count)
    {
		return _transactions[transactionId].approved.length;
    }
	
    // @dev Returns total number of transactions after filers are applied.
    function getTransactionCount(
		bool pending,
		bool executed
	)
        public
		view
        returns (uint256 count)
    {
        for (uint256 i=0; _transactions.length; i++) {
            if (_transactions[i].executed) count += 1;
		}
    }

    // @dev Returns array with key addresses, which approved transaction.
    function getApprovers(
		uint256 transactionId
	)
        public
		view
        returns (address[] confirmations)
    {
		return _transactions[transactionId].approved;
    }


}