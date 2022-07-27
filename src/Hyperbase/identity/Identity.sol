// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';

import '../../Interface/IHypercore.sol';
import '../../Interface/IIdentity.sol';

contract Identity is Context, IIdentity, ERC1155Holder {
    
    event Approval(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
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

    // @notice Mapping from OP type to number of approval required
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

    ////////////////
    // CLAIMS
    ////////////////
    
    mapping(bytes32 => Claim) internal _claims;
    mapping(uint256 => bytes32[]) internal _claimsByTopic; 

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    ////////////////
    // EXTENSIONS
    ////////////////

    mapping(address => bool) public hypercores;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    function init(
        address[] memory hypercores_,
        bytes[] memory hypercoresData_
    )
        public
        payable
        nonReentrant
        virtual
    {
        require(hypercores_.length == hypercoresData_.length, "Lengths do not match");
        if (hypercores_.length != 0) {
            unchecked { // cannot realistically overflow on human timescales
                for (uint256 i; i < hypercores_.length; i++) {
                    hypercores[hypercores_[i]] = true;

                    if (hypercoresData_[i].length != 0) {
                        (bool success, ) = hypercores_[i].call(hypercoresData_[i]);
                        require (success, "Error adding extensions");
                    }
                }
            }
        }
    }

    ////////////////
    // MODIFIERS
    ////////////////

    modifier onlySelf() {
        require(msg.sender == address(this), "Only this account can call these functions");
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
        byte32 oldKey,
        byte32 newKey,
		uint256 purpose
    )
		public
		onlySelf
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
            requiredKeyType = MANAGEMENT;
        }
		else {
            uint256 requiredKeyType = ACTION;
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
		require(required < _keys.length, "Number of keys required cannot exceed or match key count");
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
		if (getApprovalCount(transactionId) == _sigThreshold[operationType]) {
			return true;
		}
		else {
			return false;
		}
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
        for (uint256 i=0; _transactions.length; i++) {
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
        returns (address[] confirmations)
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
		bytes data
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
		bytes data
	)
        internal
        returns (uint256 transactionId)
    {
        transactionId = _transactionNonce;
        _transactions[transactionId] = Transaction({
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

    function approve(
		uint256 transactionId
	)
        public
        keyExists
        transactionExists(transactionId)
        notApproved(transactionId, _msgSender())
    {
        _approve(addressToKey(_msgSender()), transactionId)
        emit Approval(_msgSender(), transactionId);
        execute(transactionId);
    }

    function _approve(
        bytes32 key,
        uint256 transactionId
    )
        internal
    {
		_transactions[transactionId].approved.append(key);
    }

    // @notice Allows an key to revoke a approval for a transaction.
    function revokeApproval(
		uint256 transactionId
	)
        public
        keyExists
        approved(transactionId)
        notExecuted(transactionId)
    {
		delete _transactions[transactionId].approved[_msgSender()];
        emit Revocation(_msgSender(), transactionId);
    }

    // @notice Executes the transaction if fields are valid for an approved transaction.
    function execute(
		uint256 transactionId
	)
		public
    {
		require(isApproved(transactionId, getOperationType(transactionId)), "Transaction hasn't reach approval threshold");
		required(!isExecuted(transactionId), "Transaction has already been executed");
        _execute(transactionId);
    }

    function _execute(
		uint256 transactionId
    )
        internal
    {
		(success,) = _transactions[transactionId].to.call{value:(_transactions[transactionId].value)}(abi.encode(_transactions[transactionId].data, 0));
		if (success) {
			_transactions[transactionId].executed = true;
			emit Executed(transactionId, _transactions[transactionId].to, _transactions[transactionId].value, _transactions[transactionId].data);
			return true;
		}
        else {
			emit TransactionFailed(transactionId, _transactions[transactionId].to, _transactions[transactionId].value, _transactions[transactionId].data);
			return false;
		}
    }

    ////////////////////////////////////////////////////////////////
	//					   	  SIGNED TX
    ////////////////////////////////////////////////////////////////

    // @notice Allows users to sign messages of intent offline and submit them, messages are passed to one via url or QR.
    // Only takes one bytes field that contains all messages, this is split and each signature is verified. This process
    // assumes that all signatures required for a single tx will be compiled into a single bytes field before submission. 
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
        
        // verify if signatures are valid and came from correct actors;
        verifySignatures(
            _to == address(this) ? MANAGEMENT : ACTION,
            signHash, 
            _messageSignatures
        );
        
        //executes transaction
        uint256 transactionId = _submitTransaction(
            _to,
            _value,
            _data
        )

        
        
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
        uint256 _requiredKey,
        bytes32 _signHash,
        bytes _messageSignatures
    ) 
        public
        view
        returns(bool)
    {
        uint _amountSignatures = _messageSignatures.length / 72;

        // TODO This is threshold verifyer?..
        require(_amountSignatures == _approvalThreshold[_requiredKey], "Does not have enough signatures");

        bytes32 _lastKey = 0;
        for (uint256 i = 0; i < _amountSignatures; i++) {
            bytes32 _currentKey = recoverKey(_signHash, _messageSignatures, i);
            require(_currentKey > _lastKey); // assert keys are different
            require(isKeyPurpose(_currentKey, _requiredKey));
            _lastKey = _currentKey;
        }
        return true;
    }

    // @notice. 
    // @dev new verify signatures, brought inline with the transaction structure model? make it more robust and less isolated,
    // ideally executedSigned would just be a wrapper, rather than an isolated flow...
    /*
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

        // TODO This is threshold verifyer?..
        require(_amountSignatures == _approvalThreshold[_requiredKey], "Does not have enough signatures");

        bytes32 _prevKey = 0;
        for (uint256 i = 0; i < _amountSignatures; i++) {
            bytes32 _key = recoverKey(_signHash, _messageSignatures, i);
            require(_key > _prevKey); // assert keys are different
            require(isKeyPurpose(_key, _requiredKey));
            _approve(_key, transactionId);
            _prevKey = _key;
        }
        return true;
    }
    */

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

    // @notice divides bytes signature into `uint8 v, bytes32 r, bytes32 s`
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
 

    ////////////////////////////////////////////////////////////////
    //                           CLAIMS
    ////////////////////////////////////////////////////////////////

    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
        public
        override
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(issuer, topic));

        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender()), CLAIM), "Permissions: Sender does not have claim signer key");
        }

        if (_claims[claimId].issuer != issuer) {
            _claimsByTopic[topic].push(claimId);
            _claims[claimId].topic = topic;
            _claims[claimId].scheme = scheme;
            _claims[claimId].issuer = issuer;
            _claims[claimId].signature = signature;
            _claims[claimId].data = data;
            _claims[claimId].uri = uri;

            emit ClaimAdded(
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        } else {
            _claims[claimId].topic = topic;
            _claims[claimId].scheme = scheme;
            _claims[claimId].issuer = issuer;
            _claims[claimId].signature = signature;
            _claims[claimId].data = data;
            _claims[claimId].uri = uri;

            emit ClaimChanged(
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        }

        return claimId;
    }

    function removeClaim(
        bytes32 claimId
    )
        public
        override
        returns (bool success)
    {
        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender()), CLAIM), "Permissions: Sender does not have CLAIM key");
        }

        if (_claims[claimId].topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        while (_claimsByTopic[_claims[claimId].topic][claimIndex] != claimId) {
            claimIndex++;
        }

        _claimsByTopic[_claims[claimId].topic][claimIndex] = _claimsByTopic[_claims[claimId].topic][_claimsByTopic[_claims[claimId].topic].length - 1];
        _claimsByTopic[_claims[claimId].topic].pop();

        emit ClaimRemoved(
            claimId,
            _claims[claimId].topic,
            _claims[claimId].scheme,
            _claims[claimId].issuer,
            _claims[claimId].signature,
            _claims[claimId].data,
            _claims[claimId].uri
        );

        delete _claims[claimId];

        return true;
    }

    function getClaim(
        bytes32 claimId
    )
        public
        override
        view
        returns (
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        return (
            _claims[claimId].topic,
            _claims[claimId].scheme,
            _claims[claimId].issuer,
            _claims[claimId].signature,
            _claims[claimId].data,
            _claims[claimId].uri
        );
    }

    function getClaimIdsByTopic(
        uint256 topic
    )
        public
        override
        view
        returns(bytes32[] memory claimIds)
    {
        return _claimsByTopic[topic];
    }

    ////////////////////////////////////////////////////////////////
    //                         HYPERCORES 
    ////////////////////////////////////////////////////////////////
    
    function callExtension(
        address extension, 
        uint256 amount,     
        bytes calldata data
    )
        public
        payable
        nonReentrant
        virtual
        returns (bool mint, uint256 amountOut)
    {

        require(hypercores[extension] && hypercores[msg.sender], "Extension does not exist");
        
        address account;

        if (hypercores[msg.sender]) {
            account = extension;
            amountOut = amount;
            mint = abi.decode(data, (bool));
        }
        else {
            account = msg.sender;
            (mint, amountOut) = IHypercore(extension).callExtension{value: msg.value}(msg.sender, amount, data);
        }
        
        if (mint) {
            if (amountOut != 0) {
                _mint(account, amountOut); 
            }
        }
        else {
            if (amountOut != 0) {
                _burn(account, amount);
            }
        }
    }

}