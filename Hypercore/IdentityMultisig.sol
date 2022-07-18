// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// TODO keep permission levels and multi sig?

contract MultiSig {
    
    ////////////////
    // KEYS
    ////////////////

    event Approval(address indexed sender, uint indexed transactionId);
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
    uint256 constant MANAGEMENT = 1;
    uint256 constant ACTION = 2;
    uint256 constant CLAIMS = 3;
    uint256 constant ENCRYPTION = 4;
    
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

	// mapping (uint256 => mapping (bytes32 => bool)) public _sigApprovals;
	
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
        require(_sigApprovals[transactionId][addressToKey(_msgSender())]);
        _;
    }

	// Think this checks the caller is an has not approved
    modifier notApproved(
		uint256 transactionId
	) {
		// TODO check this
        require(!_sigApprovals[transactionId][addressToKey(_msgSender())]);
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

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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

	// @dev Allows to change the number of required _sigApprovals. Transaction has to be sent by wallet.
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
        // emit Approval(_msgSender(), transactionId);
        executeTransaction(transactionId);
    }


	// @dev Returns the operation type by transaction id based on the target address
    function operationType(
		uint256 transactionId
	)
        public
		returns (uint256 requiredKeyType)
	{
        if (_transactions[transactionId].to == address(this)) requiredKeyType = MANAGEMENT;
		else uint256 requiredKeyType = ACTION;
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
        if (isApproved(transactionId, operationType(transactionId))) {
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
		if (getApprovalCount(transactionId) == _sigRequirements[operationType]) {
			return true;
		}
		else {
			return false;
		}
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


















	// !  From here downwards is all in progress

    /*//////////////////////////////////////////////////////////////
							META TRANSACTIONS
    //////////////////////////////////////////////////////////////*/


    function execute(
        bytes32 _identity,
        address _to,
        uint256 _value,
        bytes _data
    ) public returns(address) {
        return _execute(_identity, msg.sender, _to, _value, _data);
    }


    function executeSigned(
        bytes32 _identity,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _hash,
        address _to,
        uint256 _value,
        bytes _data
    ) public returns(address) {
        return _execute(_identity, ecrecover(_hash, _sigV, _sigR, _sigS), _to, _value, _data);
    }


    function approveSigned(
        bytes32 _identity,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _hash,
        uint256 _id,
        bool _approve
    )
		public
		returns(address)
	{
        return _approve(_identity, ecrecover(_hash, _sigV, _sigR, _sigS), _id, _approve);
    }
    function approve(
        bytes32 _identity,
        uint256 _id,
		bool _approve
    )
		public
		returns(bool success)
	{
        return _approve(_identity, msg.sender, _id, _approve);

    }
	    bytes4 public constant CALL_PREFIX = bytes4(keccak256("callGasRelay(address,uint256,bytes32,uint256,uint256,address)"));
    bytes4 public constant APPROVEANDCALL_PREFIX = bytes4(keccak256("approveAndCallGasRelay(address,address,uint256,bytes32,uint256,uint256)"));

    event ExecutedGasRelayed(bytes32 signHash, bool success);

	// 	@notice refer to Refund Signed 3 in archive for reference
    //  @dev include ethereum signed callHash in return of gas proportional amount multiplied by `_gasPrice` of `_gasToken`
    //  allows identity of being controlled without requiring ether in key balace
    function callGasRelayed(
        address _to,
        uint256 _value,
        bytes _data,
        uint _nonce,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken, 
        bytes _messageSignatures
    ) 
        external 
    {
        uint startGas = gasleft();
        //verify transaction parameters
        require(startGas >= _gasLimit);
        require(_nonce == nonce);
        // calculates signHash
        bytes32 signHash = getSignHash(
            callGasRelayHash(
                _to,
                _value,
                keccak256(_data),
                _nonce,
                _gasPrice,
                _gasLimit,
                _gasToken                
            )
        );
        
        //verify if signatures are valid and came from correct actors;
        verifySignatures(
            _to == address(this) ? MANAGEMENT : ACTION,
            signHash, 
            _messageSignatures
        );
        
        //executes transaction
        nonce++;
        bool success = _to.call.value(_value)(_data);
        emit ExecutedGasRelayed(
            signHash,
            success
        );

        //refund gas used using contract held ERC20 tokens or ETH
        if (_gasPrice > 0) {
            uint256 _amount = 21000 + (startGas - gasleft());
            _amount = _amount * _gasPrice;
            if (_gasToken == address(0)) {
                address(msg.sender).transfer(_amount);
            } else {
                ERC20Token(_gasToken).transfer(msg.sender, _amount);
            }
        }        
    }

	// 	@notice refer to Refund Signed 3 in archive for reference
    //  @dev include ethereum signed approve ERC20 and call hash 
    function approveAndCallGasRelayed(
        address _baseToken, 
        address _to,
        uint256 _value,
        bytes _data,
        uint _nonce,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken,
        bytes _messageSignatures
    ) 
        external 
    {
        uint startGas = gasleft();
        //verify transaction parameters
        require(startGas >= _gasLimit);
        require(_nonce == nonce);
        require(_baseToken != address(0)); //_baseToken should be something!
        require(_to != address(this)); //no management with approveAndCall
        
        // calculates signHash
        bytes32 signHash = getSignHash(
            approveAndCallGasRelayHash(
                _baseToken,
                _to,
                _value,
                keccak256(_data),
                _nonce,
                _gasPrice,
                _gasLimit,
                _gasToken               
            )
        );
        
        //verify if signatures are valid and came from correct actors;
        verifySignatures(
            ACTION, //no management with approveAndCall
            signHash, 
            _messageSignatures
        );
        
        approveAndCall(
            signHash,
            _baseToken,
            _to,
            _value,
            _data
        );

        //refund gas used using contract held ERC20 tokens or ETH
        if (_gasPrice > 0) {
            uint256 _amount = 21000 + (startGas - gasleft());
            _amount = _amount * _gasPrice;
            if (_gasToken == address(0)) {
                address(msg.sender).transfer(_amount);
            } else {
                ERC20Token(_gasToken).transfer(msg.sender, _amount);
            }
        }        

    }

	// 	@notice refer to Refund Signed 3 in archive for reference
    //  @dev reverts if signatures are not valid for the signed hash and required key type. 
    function verifySignatures(
        uint256 _requiredKey,
        bytes32 _signHash,
        bytes _messageSignatures
    ) 
        public
        view
        returns(bool)
    {
        uint _amountSignatures = _messageSignatures.length / 72;
        require(_amountSignatures == purposeThreshold[_requiredKey]);
        bytes32 _lastKey = 0;
        for (uint256 i = 0; i < _amountSignatures; i++) {
            bytes32 _currentKey = recoverKey(
                _signHash,
                _messageSignatures,
                i
                );
            require(_currentKey > _lastKey); //assert keys are different
            require(isKeyPurpose(_currentKey, _requiredKey));
            _lastKey = _currentKey;
        }
        return true;
    }


	// 	@notice refer to Refund Signed 3 in archive for reference
    //  @dev get callHash
    function callGasRelayHash(
        address _to,
        uint256 _value,
        bytes32 _dataHash,
        uint _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken
    )
        public 
        view 
        returns (bytes32 _callGasRelayHash) 
    {
        _callGasRelayHash = keccak256(
            address(this), 
            CALL_PREFIX, 
            _to,
            _value,
            _dataHash,
            _nonce,
            _gasPrice,
            _gasLimit,
            _gasToken
        );
    }

    
	//	@notice refer to Refund Signed 3 in archive for reference 
    //  @dev get callHash
    function approveAndCallGasRelayHash(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes32 _dataHash,
        uint _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken
    )
        public 
        view 
        returns (bytes32 _callGasRelayHash) 
    {
        _callGasRelayHash = keccak256(
            address(this), 
            APPROVEANDCALL_PREFIX, 
            _baseToken,
            _to,
            _value,
            _dataHash,
            _nonce,
            _gasPrice,
            _gasLimit,
            _gasToken
        );
    }

	// 	@notice refer to Refund Signed 3 in archive for reference
    //  @dev Hash a hash with `"\x19Ethereum Signed Message:\n32"`
    function getSignHash(
        bytes32 _hash
    )
        pure
        public
        returns(bytes32 signHash)
    {
        signHash = keccak256("\x19Ethereum Signed Message:\n32", _hash);
    }

	// 	@notice refer to Refund Signed 3 in archive for reference
    //  @dev recovers address who signed the message 
    function recoverKey (
        bytes32 _signHash, 
        bytes _messageSignature,
        uint256 _pos
    )
        pure
        public
        returns(bytes32) 
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v,r,s) = signatureSplit(_messageSignature, _pos);
        return bytes32(
            ecrecover(
                _signHash,
                v,
                r,
                s
            )
        );
    }

	// 	@notice refer to Refund Signed 3 in archive for reference
    //  @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`
    function signatureSplit(bytes _signatures, uint256 _pos)
        pure
        public
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint pos = _pos + 1;
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(_signatures, mul(32,pos)))
            s := mload(add(_signatures, mul(64,pos)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(_signatures, mul(65,pos))), 0xff)
        }

        require(v == 27 || v == 28);
    }
    
    function approveAndCall(
        bytes32 _signHash,
        address _token,
        address _to,
        uint256 _value,
        bytes _data
    )
        private 
    {
        //executes transaction
        nonce++;
        ERC20Token(_token).approve(_to, _value);
        emit ExecutedGasRelayed(
            _signHash, 
            _to.call(_data)
        );
        
    }

}