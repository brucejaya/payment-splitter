// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import '../../Interface/IIdentity.sol';

contract Identity is Context, IIdentity, ERC1155Holder {
    
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
        bool exists; // TODO, add
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
    // EXEUCTIONS
    ////////////////
    mapping(uint256 => Transaction) internal _transactions;
    uint256 internal _transactionNonce;
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    function init(
        address initialManagementKey
    ) internal {
        bytes32 key = keccak256(abi.encode(initialManagementKey));
        _keys[key].key = key;
        _keys[key].purposes = [1];
        _keys[key].keyType = 1;
        _keysByPurpose[1].push(key);
        emit KeyAdded(key, 1, 1);
    }

    /*//////////////////////////////////////////////////////////////
                                 KEYS
    //////////////////////////////////////////////////////////////*/

    function addressToKey(
        address account
    )
        public 
        view 
    {
        return keccak256(abi.encode(account));
    }

    function getKey(
        bytes32 key
    )
        public
        override
        view
        returns(uint256[] memory purpose_, uint256 keyType_, bytes32 key_)
    {
        return (_keys[key].purposes, _keys[key].keyType, _keys[key].key);
    }

    function getKeyPurposes(
        bytes32 key
    )
        public
        override
        view
        returns(uint256[] memory purposes)
    {
        return (_keys[key].purposes);
    }

    function getKeysByPurpose(
        uint256 purpose
    )
        public
        override
        view
        returns(bytes32[] memory _keys)
    {
        return _keysByPurpose[purpose];
    }

    function addKey(
        bytes32 key,
        uint256 purpose,
        uint256 keyType
    )
        public
        override
        returns (bool success)
    {
        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender())), 1), "Permissions: Sender does not have management key");
        }

        if (_keys[key].key == key) {
            for (uint keyPurposeIndex = 0; keyPurposeIndex < _keys[key].purposes.length; keyPurposeIndex++) {
                uint256 purpose = _keys[key].purposes[keyPurposeIndex];

                if (purpose == purpose) {
                    revert("Conflict: Key already has purpose");
                }
            }

            _keys[key].purposes.push(purpose);
        } else {
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
        override
        returns (bool success)
    {
        require(_keys[key].key == key, "NonExisting: Key isn't registered");

        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender())), MANAGEMENT_KEY), "Permissions: Sender does not have management key"); // Sender has MANAGEMENTKEY
        }

        require(_keys[key].purposes.length > 0, "NonExisting: Key doesn't have such purpose");

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

    function keyHasPurpose(
        bytes32 key, 
        uint256 purpose
    )
        public
        override
        view
        returns(bool result)
    {
        Key memory key = _keys[key];
        if (key.key == 0) return false;

        for (uint keyPurposeIndex = 0; keyPurposeIndex < key.purposes.length; keyPurposeIndex++) {
            uint256 purpose = key.purposes[keyPurposeIndex];

            if (purpose == 1 || purpose == purpose) return true;
        }

        return false;
    }

    /*//////////////////////////////////////////////////////////////
                                 CLAIMS
    //////////////////////////////////////////////////////////////*/

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
            require(keyHasPurpose(addressToKey(_msgSender())), CLAIM_SIGNER_KEY), "Permissions: Sender does not have claim signer key");
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
            require(keyHasPurpose(addressToKey(_msgSender())), CLAIM_SIGNER_KEY), "Permissions: Sender does not have CLAIM key");
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

    /*//////////////////////////////////////////////////////////////
                                MULTI-SIGNATURE
    //////////////////////////////////////////////////////////////*/

	// TODO see ERC-191 for more details on this
    /*
	function getMessageHash(
        address to,
        uint256 value,
        bytes memory data,
        uint nonce,
        uint gasPrice,
        uint gasLimit,
        address gasToken,
        uint8 operationType,
        bytes memory extraHash
    )
        public
        view
        returns (bytes32 messageHash)
    {
        // bytes4 callPrefix;
        // assembly {
            // callPrefix := mload(add(data, 32))
        // }

        return keccak256(
            abi.encodePacked(
                // byte(0x19),      // ERC-191 - the initial 0x19 byte
                // byte(0x0),       // ERC-191 - the version byte
                address(this),      // this
                to,
                value,
                keccak256(data),   // data hash
                nonce,
                gasPrice,
                gasLimit,
                gasToken,
                operationType,
                // callPrefix,
                extraHash
                
            )
        );
    }

    function haveEnoughValidSignatures(
        uint256 operationType,
        bytes32 messageHash,
        bytes memory messageSignatures
    )
        internal
        view
        returns (bool hasEnough)
    {

        uint256 numSignatures = messageSignatures.length / 65;
        uint256 validSignatureCount = 0;

        for (uint pos = 0; pos < numSignatures; pos++) {
            uint8 v;
            bytes32 r;
            bytes32 s;

            assembly{
                r := mload(add(messageSignatures, add(32, mul(65,pos))))
                s := mload(add(messageSignatures, add(64, mul(65,pos))))
                // Here we are loading the last 32 bytes, including 31 bytes
                // of 's'. There is no 'mload8' to do this.
                //
                // 'byte' is not working due to the Solidity parser, so lets
                // use the second best option, 'and'
                v := mload(add(messageSignatures, add(65, mul(65,pos))))
            }

            if (keyHasPurpose(_keys[bytes32(ecrecover(messageHash, v, r, s))], operationType)) {
                validSignatureCount++;
            }
        }

        if (validSignatureCount >= sigRequirementByKeyType[operationType]) {
            return true;
        }

        return false;
    }

    function executeSigned(
        address to,
        address from,
        uint256 value,
        bytes memory data,
        uint nonce,
        uint gasPrice,
        uint gasLimit,
        address gasToken,
        uint8 operationType,
        bytes memory extraHash,
        bytes memory messageSignatures
    )
        public
    {

        uint256 startGas = gasleft();
        require(supportedOpType[operationType]);
        
        require(startGas >= gasLimit);

        bytes32 msgHash = getMessageHash(to, value, data, nonce, gasPrice, gasLimit, gasToken, operationType, extraHash);
        
        uint256 requiredKeyType = ACTION_KEY;
        if (to == address(this)) {
            requiredKeyType = MANAGEMENT_KEY;
        }
        require(haveEnoughValidSignatures(requiredKeyType, msgHash, messageSignatures));

        uint256 _transactionId = _execute(to, value, data);

        uint256 refundAmount = (startGas - gasleft()) * gasPrice;

        if (gasToken == address(0)) {
            require(address(this).balance > refundAmount);
            payable(_msgSender()).transfer(refundAmount);
        } else {
            require(IERC20(gasToken).balanceOf(address(this)) > refundAmount);
            require(IERC20(gasToken).transfer(_msgSender(), refundAmount));
        }
    }
    */

    /*//////////////////////////////////////////////////////////////
                                EXECUTIONS
    //////////////////////////////////////////////////////////////*/

    function approve(
        uint256 id,
        bool approve
    )
        public
        override
        returns (bool success)
    {
        require(keyHasPurpose(addressToKey(_msgSender())), ACTION_KEY), "Sender does not have action key");

        emit Approved(id, approve);

        if (approve == true) {
            _transactions[id].approved = true;
            (success,) = _transactions[id].to.call{value:(_transactions[id].value)}(abi.encode(_transactions[id].data, 0));
            if (success) {
                _transactions[id].executed = true;
                emit Executed(id, _transactions[id].to, _transactions[id].value, _transactions[id].data);
                return true;
            } else {
                emit TransactionFailed(id, _transactions[id].to, _transactions[id].value, _transactions[id].data);
                return false;
            }
        } else {
            _transactions[id].approved = false;
        }
        return true;
    }

    function execute(
        address to, 
        uint256 value, 
        bytes memory data
    )
        public
        override
        payable
        returns (uint256 _transactionId)
    {
        uint256 _transactionId = _execute(to, value, data);
        return _transactionId;
    }

    function _execute(
        address _to, 
        uint256 _value, 
        bytes memory _data
    )
        internal
        returns (uint256 _transactionId)
    {
        
        require(!_transactions[_transactionNonce].executed, "Already executed");
        _transactions[_transactionNonce].to = _to;
        _transactions[_transactionNonce].value = _value;
        _transactions[_transactionNonce].data = _data;

        emit TransactionRequested(_transactionNonce, _to, _value, _data);

        if (keyHasPurpose(addressToKey(_msgSender())), ACTION_KEY)) {
            approve(_transactionNonce, true);
        }

        _transactionNonce++;
        return _transactionNonce-1;
    }

}