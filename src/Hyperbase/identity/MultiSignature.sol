// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// executed signed messages and refund

// include approve and call erc20?

contract MultiSig {

    event ExecutedGasRelayed(bytes32 signHash, bool success);
	
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
    // TX
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


    /*//////////////////////////////////////////////////////////////
								TX STATUS
    //////////////////////////////////////////////////////////////*/
	
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


    // @dev include ethereum signed callHash in return of gas proportional amount multiplied by `_gasPrice` of `_gasToken`
    // allows identity of being controlled without requiring ether in key balace
    // sigs must be gathered beforehand
    function executeSigned(
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

        // verify transaction parameters
        require(startGas >= _gasLimit);
        require(nonce == _nonce);

        // calculates signHash
        bytes32 signHash = getSignHash(
            getTransactionHash(
                _to,
                _value,
                keccak256(_data),
                _nonce,
                _gasPrice,
                _gasLimit,
                _gasToken
            )
        );
        
        // verify if signatures are valid and came from correct actors;
        verifySignatures(
            _to == address(this) ? MANAGEMENT,
            signHash, 
            _messageSignatures
        );
        
        //executes transaction
        nonce++;
        bool success = _to.call.value(_value)(_data);
        emit ExecutedGasRelayed(signHash, success);

        emit ExecutedGasRelayed(signHash, success);

        if (_gasPrice > 0) {
            uint256 _amount = 21000 + (startGas - gasleft());
            _amount = _amount * _gasPrice;
                
            if (_gasToken == address(0)) {
                require(address(this).balance > _value);
                msg.sender.transfer(_value);
            }
            else {
                require(ERC20Interface(_gasToken).balanceOf(address(this)) > _value);
                require(ERC20Interface(_gasToken).transfer(msg.sender, _value));
            }
        }        
    }

    function execute(
        address _to,
        uint256 _value,
        bytes _data
    )
        public
        returns (uint256 executionId)
    {
        uint256 _executionId = transactionCount + 1;
        transactions[_executionId].to = _to;
        transactions[_executionId].value = _value;
        transactions[_executionId].data = _data;

        emit ExecutionRequested(_executionId, _to, _value, _data);
        
        Key storage senderKey = keys[addressToBytesKey(msg.sender)];
        if (senderKey.purposeExists[1] || senderKey.purposeExists[2]) {
            //  check the number of sigs, boolean style...
            approve(_executionId, true);
        }
        transactionCount++;

        return _executionId;
    }

    // See submit tx in other 
    function approve(
        uint256 transactionId,
        bool approve
    )
        public
        returns (bool success)
    {
        Key storage senderKey = keys[addressToBytesKey(msg.sender)];
        require (!transactions[transactionId].executed);
        require (senderKey.purposeExists[1] || senderKey.purposeExists[2]);

        if (approve) {

            // todo, if approve transaction, approve transaction
            // if transaction has enough approvals, execute
            
            if (transactions[transactionId].to == address(this)) {
                require (senderKey.purposeExists[1]);
            }

             = transactions[transactionId].to;
             = transactions[transactionId].value;
             = transactions[transactionId].data;

            bool success = _to.call.value(_value)(_data);
            
            bool success = transactions[transactionId].executed = transactions[transactionId].to.call.value(_value)(_data);

            emit Executed(transactionId, transactions[transactionId].to, transactions[transactionId].value, transactions[transactionId].data);
        }
        else {
            return false;
        }

    }

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

    /*//////////////////////////////////////////////////////////////
                           SIGNATURE UTILS
    //////////////////////////////////////////////////////////////*/

    // @dev get the transaction hash
    function getTransactionHash(
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
        returns (bytes32 callHash) 
    {
        callHash = keccak256(address(this), CALL_PREFIX, _to, _value, _dataHash, _nonce, _gasPrice, _gasLimit, _gasToken);
    }

    // @dev reverts if signatures are not valid for the signed hash and required key type. 
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

        // This is threshold verifyer?..
        require(_amountSignatures == _approvalThreshold[_requiredKey]);

        bytes32 _lastKey = 0;
        for (uint256 i = 0; i < _amountSignatures; i++) {
            bytes32 _currentKey = recoverKey(_signHash, _messageSignatures, i);
            require(_currentKey > _lastKey); // assert keys are different
            require(isKeyPurpose(_currentKey, _requiredKey));
            _lastKey = _currentKey;
        }
        return true;
    }

    // @dev Hash a hash with `"\x19Ethereum Signed Message:\n32"`
    function getSignHash(
        bytes32 _hash
    )
        pure
        public
        returns(bytes32 signHash)
    {
        signHash = keccak256("\x19Ethereum Signed Message:\n32", _hash);
    }

    // @dev recovers address who signed the message 
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

    // @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`
    function signatureSplit(
        bytes _signatures,
        uint256 _pos
    )
        pure
        public
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint pos = _pos + 1;
        // The signature format is a compact form of:
        //  {bytes32 r}{bytes32 s}{uint8 v}
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
    
}