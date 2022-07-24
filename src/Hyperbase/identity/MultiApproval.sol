// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Required multiple bolean confirmations

contract MultiSig {
	
    event Approval(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    
    ////////////////
    // KEYS
    ////////////////

    uint256 constant MANAGEMENT = 1;
    uint256 constant ACTION = 2;
    uint256 constant CLAIM = 3;
    uint256 constant ENCRYPTION = 4;
    
    mapping(uint256 => bytes32[]) internal _keysByPurpose;
    mapping(bytes32 => Key) internal _keys;

    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    ////////////////
    // MULTI-SIG
    ////////////////

    // @dev Mapping from OP type to number of approval required
    mapping(uint256 => uint256) internal _approvalThreshold;
    
    ////////////////
    // TRANSACTIONS
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
    // MODIFIERS
    ////////////////

    function requireSelfCall() private view {
        require(msg.sender == address(this), "Only this account can call these functions");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }

    ////////////////////////////////////////////////////////////////
                                 KEYS
    ////////////////////////////////////////////////////////////////

    function addressToKey(
        address account
    )
        internal 
        pure
        returns (bytes32 key)
    {
        return keccak256(abi.encode(account));
    }

    function getKey(
        bytes32 key
    )
        internal
        override
        view
        returns(uint256[] memory purpose_, uint256 keyType_, bytes32 key_)
    {
        return (_keys[key].purposes, _keys[key].keyType, _keys[key].key);
    }

    function getKeyPurposes(
        bytes32 key
    )
        internal
        override
        view
        returns(uint256[] memory purposes)
    {
        return (_keys[key].purposes);
    }

    function getKeysByPurpose(
        uint256 purpose
    )
        internal
        override
        view
        returns(bytes32[] memory keys_)
    {
        return _keysByPurpose[purpose];
    }

    function keyHasPurpose(
        bytes32 key, 
        uint256 purpose
    )
        internal
        override
        view
        returns(bool result)
    {
        if (_keys[key].key != 0) return false;

        for (uint keyPurposeIndex = 0; keyPurposeIndex < _keys[key].purposes.length; keyPurposeIndex++) {
            uint256 purpose_ = _keys[key].purposes[keyPurposeIndex];

            if (purpose == 1 || purpose == purpose_) return true;
        }
        return false;
    }

    function addKey(
        bytes32 key,
        uint256 purpose,
        uint256 keyType
    )
		public
		authorized
        override
        returns (bool success)
    {
        if (_keys[key].key == key) {
            for (uint keyPurposeIndex = 0; keyPurposeIndex < _keys[key].purposes.length; keyPurposeIndex++) {
                uint256 purpose_ = _keys[key].purposes[keyPurposeIndex];
                if (purpose == purpose_) {
                    revert("Conflict: Key already has purpose");
                }
            }
            _keys[key].purposes.push(purpose);
        }
		else {
            _keys[key].key = key;
            _keys[key].purposes = [purpose];
            _keys[key].keyType = keyType;
        }
        _keysByPurpose[purpose].push(key);
        emit KeyAdded(key, purpose, keyType);
        return true;
    }

    function removeKey(
        bytes32 key,
        uint256 purpose
    )
		public
		authorized
        override
        returns (bool success)
    {
        require(_keys[key].key == key, "NonExisting: Key isn't registered");
        require(_keys[key].purposes.length > 0, "NonExisting: Key doesn't have this purpose");
        uint purposeIndex = 0;
        while (_keys[key].purposes[purposeIndex] != purpose) {
            purposeIndex++;

            if (purposeIndex >= _keys[key].purposes.length) {
                break;
            }
        }
        require(purposeIndex < _keys[key].purposes.length, "NonExisting: Key doesn't have such purpose");
        _keys[key].purposes[purposeIndex] = _keys[key].purposes[_keys[key].purposes.length - 1];
        _keys[key].purposes.pop();
        uint keyIndex = 0;
        while (_keysByPurpose[purpose][keyIndex] != key) {
            keyIndex++;
        }
        _keysByPurpose[purpose][keyIndex] = _keysByPurpose[purpose][_keysByPurpose[purpose].length - 1];
        _keysByPurpose[purpose].pop();
        uint keyType = _keys[key].keyType;
        if (_keys[key].purposes.length == 0) {
            delete _keys[key];
        }
        emit KeyRemoved(key, purpose, keyType);
        return true;
    }
	
    // @dev Allows to swap/replace an owner from the Safe with another key.
    function swapKey(
        byte32 oldKey,
        byte32 newKey,
		uint256 purpose
    )
		public
		authorized
	{

        require(newKey != addressToKey(address(0)), "Can't add zero address");
        require(newKey != oldKey, "New and old key can't be the same");
        require(newKey != address(this), "Can't add this address as a key");
        require(_keys[newKey].key == 0, "Key already exists");
		// purpose checks needed...
		removeKey(oldKey, purpose);
		addKey(newKey, purpose);
    }


    ////////////////////////////////////////////////////////////////
							SIG THRESHOLD
    ////////////////////////////////////////////////////////////////

	// @dev Returns the operation type by transaction id based on the target address
    function getOperationType(
		uint256 transactionId
	)
        public
		returns (uint256 requiredKeyType)
	{
        if (_transactions[transactionId].to == address(this)) requiredKeyType = MANAGEMENT;
		else uint256 requiredKeyType = ACTION;
	}

	// @dev Returns number of signatures required.
    function getThreshold(
		uint256 operationType
	)
		public
		view
		returns (uint256)
	{
        return _approvalThreshold[operationType];
    }

	// @dev Allows to change the number of required signatures required for a given operation type.
    function changeApprovalThreshold(
		uint256 operationType,
		uint256 required
	)
        public
		authorized
    {
        require(required != 0, "Can't set the number of keys required to zero!");
		require(required < _keys.length, "Number of keys required cannot exceed or match key count");
		_approvalThreshold[operationType] = required;
        RequirementChange(operationType, required);
    }


    ////////////////////////////////////////////////////////////////
								TX STATUS
    ////////////////////////////////////////////////////////////////
	
    // @dev Returns the approval status of a transaction.
    function isApproved(
		uint256 transactionId,
		uint256 operationType
	)
        public
		view
        returns (bool)
    {
		if (getApprovalCount(transactionId) == _sigThreshold[operationType]) {
			return true;
		}
		else {
			return false;
		}
    }

    // @dev Returns the execution status of a transaction.
	function isExecuted(
		uint256 transactionId
	) 
        public
		view
        returns (bool)
	{
        if (_transactions[transactionId].executed) {
			return true;
		}
		else {
			return false;
		}
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

    // @dev Returns number of confirmations of a transaction.
    function getApprovalCount(
		uint256 transactionId
	)
        public
		view
        returns (uint256 count)
    {
		return _transactions[transactionId].approved.length;
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


    ////////////////////////////////////////////////////////////////
								SUBMIT TX
    ////////////////////////////////////////////////////////////////
	

    // @dev Allows an key to submit and approved a transaction.
    function submitTransaction(
		address to,
		uint256 value,
		bytes data
	)
        public
        returns (uint256 transactionId)
    {
        transactionId = _submitTransaction(to, value, data);
        approveTransaction(transactionId);
    }

    // @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    function _submitTransaction(
		address to,
		uint256 value,
		bytes data
	)
        internal
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

    ////////////////////////////////////////////////////////////////
							 APPROVE TX
    ////////////////////////////////////////////////////////////////

	// !  this need to change to signing transactions, rather than just setting bool to true, right?

	// !  so the first gnosis does not allow for gasless tx, it just collects peoples approvals and when it has enought it executs

	// !  the second version of gnosis, same as ___ takes offline signatures and allows 

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
        // emit Approval(_msgSender(), transactionId);
        executeTransaction(transactionId);
    }

    // @dev Allows an key to revoke a approval for a transaction.
    function revokeApproval(
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

    // @dev Allows anyone to execute a approved transaction.
    function _execute(
		uint256 transactionId
	)
		internal
    {
		require(isApproved(transactionId, getOperationType(transactionId)), "Transaction hasn't reach approval threshold");
		required(!isExecuted(transactionId), "Transaction has already been executed");
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