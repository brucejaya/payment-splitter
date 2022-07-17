// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import '../../Interface/IIdentity.sol';

contract Identity is IIdentity, ERC1155Holder {
    
    ////////////////
    // KEYS
    ////////////////
    uint256 constant MANAGEMENT_KEY = 1;
    uint256 constant ACTION_KEY = 2;
    uint256 constant CLAIM_SIGNER_KEY = 3;
    uint256 constant ENCRYPTION_KEY = 4;
    
    mapping(uint256 => bytes32[]) internal keysByPurpose;
    mapping(bytes32 => Key) internal keys;

    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    ////////////////
    // CLAIMS
    ////////////////
    mapping(bytes32 => Claim) internal claims;
    mapping(uint256 => bytes32[]) internal claimsByTopic; 

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
    uint256 internal executionNonce;
    mapping(uint256 => Execution) internal executions;
    
    struct Execution {
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
        keys[key].key = key;
        keys[key].purposes = [1];
        keys[key].keyType = 1;
        keysByPurpose[1].push(key);
        emit KeyAdded(key, 1, 1);
    }

    /*//////////////////////////////////////////////////////////////
                                 KEYS
    //////////////////////////////////////////////////////////////*/

    function getKey(
        bytes32 key
    )
        public
        override
        view
        returns(uint256[] memory purpose_, uint256 keyType_, bytes32 key_)
    {
        return (keys[key].purposes, keys[key].keyType, keys[key].key);
    }

    function getKeyPurposes(
        bytes32 key
    )
        public
        override
        view
        returns(uint256[] memory purposes)
    {
        return (keys[key].purposes);
    }

    function getKeysByPurpose(
        uint256 purpose
    )
        public
        override
        view
        returns(bytes32[] memory keys)
    {
        return keysByPurpose[purpose];
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
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key");
        }

        if (keys[key].key == key) {
            for (uint keyPurposeIndex = 0; keyPurposeIndex < keys[key].purposes.length; keyPurposeIndex++) {
                uint256 purpose = keys[key].purposes[keyPurposeIndex];

                if (purpose == purpose) {
                    revert("Conflict: Key already has purpose");
                }
            }

            keys[key].purposes.push(purpose);
        } else {
            keys[key].key = key;
            keys[key].purposes = [purpose];
            keys[key].keyType = keyType;
        }

        keysByPurpose[purpose].push(key);

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
        require(keys[key].key == key, "NonExisting: Key isn't registered");

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), MANAGEMENT_KEY), "Permissions: Sender does not have management key"); // Sender has MANAGEMENTKEY
        }

        require(keys[key].purposes.length > 0, "NonExisting: Key doesn't have such purpose");

        uint purposeIndex = 0;
        while (keys[key].purposes[purposeIndex] != purpose) {
            purposeIndex++;

            if (purposeIndex >= keys[key].purposes.length) {
                break;
            }
        }

        require(purposeIndex < keys[key].purposes.length, "NonExisting: Key doesn't have such purpose");

        keys[key].purposes[purposeIndex] = keys[key].purposes[keys[key].purposes.length - 1];
        keys[key].purposes.pop();

        uint keyIndex = 0;

        while (keysByPurpose[purpose][keyIndex] != key) {
            keyIndex++;
        }

        keysByPurpose[purpose][keyIndex] = keysByPurpose[purpose][keysByPurpose[purpose].length - 1];
        keysByPurpose[purpose].pop();

        uint keyType = keys[key].keyType;

        if (keys[key].purposes.length == 0) {
            delete keys[key];
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
        Key memory key = keys[key];
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

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), CLAIM_SIGNER_KEY), "Permissions: Sender does not have claim signer key");
        }

        if (claims[claimId].issuer != issuer) {
            claimsByTopic[topic].push(claimId);
            claims[claimId].topic = topic;
            claims[claimId].scheme = scheme;
            claims[claimId].issuer = issuer;
            claims[claimId].signature = signature;
            claims[claimId].data = data;
            claims[claimId].uri = uri;

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
            claims[claimId].topic = topic;
            claims[claimId].scheme = scheme;
            claims[claimId].issuer = issuer;
            claims[claimId].signature = signature;
            claims[claimId].data = data;
            claims[claimId].uri = uri;

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
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), CLAIM_SIGNER_KEY), "Permissions: Sender does not have CLAIM key");
        }

        if (claims[claimId].topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        while (claimsByTopic[claims[claimId].topic][claimIndex] != claimId) {
            claimIndex++;
        }

        claimsByTopic[claims[claimId].topic][claimIndex] = claimsByTopic[claims[claimId].topic][claimsByTopic[claims[claimId].topic].length - 1];
        claimsByTopic[claims[claimId].topic].pop();

        emit ClaimRemoved(
            claimId,
            claims[claimId].topic,
            claims[claimId].scheme,
            claims[claimId].issuer,
            claims[claimId].signature,
            claims[claimId].data,
            claims[claimId].uri
        );

        delete claims[claimId];

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
            claims[claimId].topic,
            claims[claimId].scheme,
            claims[claimId].issuer,
            claims[claimId].signature,
            claims[claimId].data,
            claims[claimId].uri
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
        return claimsByTopic[topic];
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

            if (keyHasPurpose(keys[bytes32(ecrecover(messageHash, v, r, s))], operationType)) {
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

        uint256 executionId = _execute(to, value, data);

        uint256 refundAmount = (startGas - gasleft()) * gasPrice;

        if (gasToken == address(0)) {
            require(address(this).balance > refundAmount);
            payable(msg.sender).transfer(refundAmount);
        } else {
            require(IERC20(gasToken).balanceOf(address(this)) > refundAmount);
            require(IERC20(gasToken).transfer(msg.sender, refundAmount));
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
        require(keyHasPurpose(keccak256(abi.encode(msg.sender)), ACTION_KEY), "Sender does not have action key");

        emit Approved(id, approve);

        if (approve == true) {
            executions[id].approved = true;

            (success,) = executions[id].to.call{value:(executions[id].value)}(abi.encode(executions[id].data, 0));

            if (success) {
                executions[id].executed = true;

                emit Executed(id, executions[id].to, executions[id].value, executions[id].data);

                return true;
            } else {

                emit ExecutionFailed(id, executions[id].to, executions[id].value, executions[id].data);

                return false;
            }
        } else {
            executions[id].approved = false;
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
        returns (uint256 executionId)
    {
        uint256 executionId = _execute(to, value, data);
        return executionId;
    }

    function _execute(
        address _to, 
        uint256 _value, 
        bytes memory _data
    )
        internal
        returns (uint256 executionId)
    {
        
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encode(msg.sender)), ACTION_KEY)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

}