// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';

import '../../Interface/IHypercore.sol';
import '../../Interface/IIdentity.sol';

contract Identity is Context, IIdentity, ERC1155Holder {
	
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

    // @notice Mapping from op type to number of approval required
    mapping(uint256 => uint256) internal _approvalThreshold;
        
    ////////////////
    // TX
    ////////////////

    mapping(uint256 => Transaction) internal _transactions;
    uint256 internal _transactionNonce;
    
    struct Transaction {
        bool exists;
        address to;
        uint256 value;
        bytes data;
        bytes32[] approved;
        bool executed;
    }

    bytes4 public constant CALL_PREFIX = bytes4(keccak256("callGasRelay(address,uint256,bytes32,uint256,uint256,address)"));

    ////////////////
    // MODIFIERS
    ////////////////

    modifier onlySelf() {
        require(msg.sender == address(this), "Only this account can call these functions");
        _;
    }
    
    modifier keyExists() {
        require(_keys[addressToKey(_msgSender())].purposes.length > 0, "Key does not exist");
        _;
    }

    ////////////////////////////////////////////////////////////////
    //                           KEYS
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
		onlySelf
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
		onlySelf
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
	
    // @notice Allows to swap/replace an owner from the Safe with another key.
    function swapKey(
        bytes32 oldKey,
        bytes32 newKey,
        uint256 purpose,
        uint256 keyType
    )
        public
        onlySelf
	{
        require(newKey != addressToKey(address(0)), "Can't add zero address");
        require(newKey != oldKey, "New and old key can't be the same");
        require(newKey != addressToKey(address(this)), "Can't add this address as a key");
        require(_keys[newKey].key == 0, "Key already exists");
		removeKey(oldKey, purpose);
		addKey(newKey, purpose, keyType);
    }

    ////////////////////////////////////////////////////////////////
	//						SIG THRESHOLD
    ////////////////////////////////////////////////////////////////

	// @notice Returns the operation type by transaction id based on the target address
    function getOperationType(
		uint256 transactionId
	)
        public
		returns (uint256 requiredKeyType)
	{
        if (_transactions[transactionId].to == address(this)) {
            return MANAGEMENT;
        }
		else {
            return ACTION;
        }
	}

	// @notice Returns number of signatures required.
    function getThreshold(
		uint256 operationType
	)
		public
		view
		returns (uint256)
	{
        return _approvalThreshold[operationType];
    }

	// @notice Allows to change the number of required signatures required for a given operation type.
    function changeApprovalThreshold(
		uint256 operationType,
		uint256 required
	)
        public
		onlySelf
    {
        require(required != 0, "Can't set the number of keys required to zero!");
		require(required < _keysByPurpose[operationType].length, "Number of keys required cannot exceed or match key count");
		_approvalThreshold[operationType] = required;
        RequirementChange(operationType, required);
    }

    ////////////////////////////////////////////////////////////////
	//							TX STATUS
    ////////////////////////////////////////////////////////////////
	
    // @notice Returns the approval status of a transaction.
    function isApproved(
		uint256 transactionId,
		uint256 operationType
	)
        public
		view
        returns (bool)
    {
		if (getApprovalCount(transactionId) == _approvalThreshold[operationType]) {
			return true;
		}
		else {
			return false;
		}
    }
    
    // @notice Returns the status of if the key is an approver
    function isApprover(
		uint256 transactionId,
        bytes32 key
    )
        public
        returns (bool hasApproved)
    {
        bytes32[] memory approvers = _transactions[transactionId].approved;
        for (uint i = 0; i < approvers.length; i++) {
            if (approvers[i] == key) {
                return true;
            }
        }
        return false;
    }


    // @notice Returns the execution status of a transaction.
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

    // @notice Returns total number of transactions after filers are applied.
    function getTransactionCount(
		bool pending,
		bool executed
	)
        public
		view
        returns (uint256 count)
    {
        for (uint256 i=0; _transactionNonce; i++) {
            if (_transactions[i].executed) count++;
		}
    }

    // @notice Returns number of confirmations of a transaction.
    function getApprovalCount(
		uint256 transactionId
	)
        public
		view
        returns (uint256 count)
    {
		return _transactions[transactionId].approved.length;
    }

    // @notice Returns array with key addresses, which approved transaction.
    function getApprovers(
		uint256 transactionId
	)
        public
		view
        returns (address[] memory confirmations)
    {
		return _transactions[transactionId].approved;
    }

    ////////////////////////////////////////////////////////////////
	//					   	 MULTI-APPROVAL
    ////////////////////////////////////////////////////////////////

    // @notice Allows a key to submit and approved a transaction.
    function submitTransaction(
		address to,
		uint256 value,
		bytes memory data
	)
        public
        returns (uint256 transactionId)
    {
        transactionId = _submitTransaction(to, value, data);
        approve(transactionId);
    }

    // @notice Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    function _submitTransaction(
		address to,
		uint256 value,
		bytes memory data
	)
        internal
        returns (uint256 transactionId)
    {
        transactionId = _transactionNonce;
        _transactions[transactionId] = Transaction({
            exists: true,
            to: to,
            value: value,
            data: data,
            approved: false,
            executed: false
        });
        // TODO check the transaction _transactionNonce is incrementing correctly
        _transactionNonce++;
        emit Submission(transactionId);
    }

    // @notice Public approve function
    function approve(
		uint256 transactionId
	)
        public
        keyExists
    {
        require(_transactions[transactionId].exists, "Transaction does not exist");
        require(!isApprover(transactionId, addressToKey(_msgSender())), "Key has already confirmed");
        _approve(addressToKey(_msgSender()), transactionId);
        emit Approval(_msgSender(), transactionId);
        execute(transactionId);
    }

    // @notice Allows an key to revoke a approval for a transaction.
    function revokeApproval(
		uint256 transactionId
	)
        public
        keyExists
    {
        require(isApprover(transactionId, addressToKey(_msgSender())), "Must have approved to revoke approval");
        require(!_transactions[transactionId].executed, "Transaction has already bee executed");
		delete _transactions[transactionId].approved[addressToKey(_msgSender())];
        emit Revocation(_msgSender(), transactionId);
    }

    // @notice Internal approve function.
    function _approve(
        bytes32 key,
        uint256 transactionId
    )
        internal
    {
		_transactions[transactionId].approved.push(key);
    }

    // @notice Executes the transaction if fields are valid for an approved transaction.
    function execute(
		uint256 transactionId
	)
		public
    {
		require(isApproved(transactionId, getOperationType(transactionId)), "Transaction hasn't reach approval threshold");
		require(!isExecuted(transactionId), "Transaction has already been executed");
        _execute(transactionId);
    }

    // @notice Internal execute function
    function _execute(
		uint256 transactionId
    )
        internal
        returns (bool success)
    {
        (success,) = _transactions[transactionId].to.call{
            value:(_transactions[transactionId].value)
        }(abi.encode(_transactions[transactionId].data, 0));
        if (success) {
            _transactions[transactionId].executed = true;
            emit Executed(
                transactionId,
                _transactions[transactionId].to,
                _transactions[transactionId].value,
                _transactions[transactionId].data
            );
            return true;
        } else {
            emit ExecutionFailed(
                transactionId,
                _transactions[transactionId].to,
                _transactions[transactionId].value,
                _transactions[transactionId].data
            );
            return false;
        }
    }

    ////////////////////////////////////////////////////////////////
	//					   	  SIGNED TX
    ////////////////////////////////////////////////////////////////

    // @notice Allows users to sign messages of intent offline and submit them, messages are passed to one via url or QR.
    // Only takes one bytes field that contains all messages, this is split and each signature is verified. This process
    // assumes that all signatures required for a single tx will be compiled into a single bytes field before submission. 
    function submitSigned(
        address _to,
        uint256 _value,
        bytes memory _data,
        uint _nonce,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken, 
        bytes memory _messageSignatures
    ) 
        external 
        returns (bool success)
    {
        uint startGas = gasleft();

        // verify transaction parameters
        require(startGas >= _gasLimit);
        require(_transactionNonce == _nonce);

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
        
        //executes transaction
        uint256 transactionId = _submitTransaction(
            _to,
            _value,
            _data
        );

        // verify if signatures are valid and came from correct actors;
        approveSigned(
            _to == address(this) ? MANAGEMENT : ACTION,
            signHash, 
            _messageSignatures
        );

        execute(transactionId);

        emit ExecutedGasRelayed(signHash, success);

        if (_gasPrice > 0) {
            uint256 _amount = 21000 + (startGas - gasleft());
            _amount = _amount * _gasPrice;
                
            if (_gasToken == address(0)) {
                require(address(this).balance > _value);
                msg.sender.send(_value);
            }
            else {
                require(IERC20(_gasToken).balanceOf(address(this)) > _value);
                require(IERC20(_gasToken).transfer(msg.sender, _value));
            }
        }        
    }

    // @notice Splits and verifies signatures, 
    function approveSigned(
        uint256 _requirePurpose,
        bytes32 _signHash,
        bytes _messageSignatures
    ) 
        public
        view
        returns(bool)
    {
        uint _amountSignatures = _messageSignatures.length / 72;

        bytes32 _prevKey = 0;
        for (uint256 i = 0; i < _amountSignatures; i++) {
            bytes32 _key = recoverKey(_signHash, _messageSignatures, i);
            require(_key > _prevKey); // assert keys are different
            require(keyHasPurpose(_key, _requirePurpose));
            _approve(_key, transactionId);
            _prevKey = _key;
        }
        return true;
    }

    ////////////////////////////////////////////////////////////////
    //                      SIGNATURE UTILS
    ////////////////////////////////////////////////////////////////

    // @notice get the transaction hash
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
        callHash = keccak256(
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

    // @notice reverts if signatures are not valid for the signed hash and required key type. 
    function verifySignatures(
        uint256 _requirePurpose,
        bytes32 _signHash,
        bytes memory _messageSignatures
    ) 
        public
        view
        returns(bool)
    {
        uint _amountSignatures = _messageSignatures.length / 72;

        // TODO This is threshold verifyer?..
        require(_amountSignatures == _approvalThreshold[_requirePurpose], "Does not have enough signatures");

        bytes32 _lastKey = 0;
        for (uint256 i = 0; i < _amountSignatures; i++) {
            bytes32 _currentKey = recoverKey(_signHash, _messageSignatures, i);
            require(_currentKey > _lastKey); // assert keys are different
            require(keyHasPurpose(_currentKey, _requirePurpose));
            _lastKey = _currentKey;
        }
        return true;
    }


    // @notice Hash a hash with `"\x19Ethereum Signed Message:\n32"`
    function getSignHash(
        bytes32 _hash
    )
        pure
        public
        returns(bytes32 signHash)
    {
        signHash = keccak256("\x19Ethereum Signed Message:\n32", _hash);
    }

    // @notice recovers address who signed the message 
    function recoverKey (
        bytes32 _signHash, 
        bytes memory _messageSignature,
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

    // @notice divides bytes signature into `uint8 v, bytes32 r, bytes32 s`
    function signatureSplit(
        bytes memory _signatures,
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