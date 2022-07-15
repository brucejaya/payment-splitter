// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import './IdentityStorage.sol';

import '../../Interface/IIdentity.sol';

/**
 * @dev Implementation of the `IERC734` "KeyHolder" as `IdentityKeys` and the `IERC735` "ClaimHolder" as `IdentityClaims` interfaces into a common Identity Contract.
 */

contract Identity is IdentityStorage, IIdentity, ERC1155Holder {


    bool private initialized = false;
    bool private canInteract = true;

    constructor(address initialManagementKey, bool _isLibrary) {
        canInteract = !_isLibrary;

        if (canInteract) {
            _Identity_init(initialManagementKey);
        } else {
            initialized = true;
        }
    }

    /**
     * @notice Prevent any direct calls to the implementation contract (marked by canInteract = false).
     */
    modifier delegatedOnly() {
        require(canInteract == true, "Interacting with the library contract is forbidden.");
        _;
    }

    /**
     * @notice When using this contract as an implementation for a proxy, call this initializer with a delegatecall.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the ONCHAINID.
     */
    function initialize(address initialManagementKey) public {
        _Identity_init(initialManagementKey);
    }

    /**
     * @notice Computes if the context in which the function is called is a constructor or not.
     *
     * @return true if the context is a constructor.
     */
    function _isConstructor() private view returns (bool) {
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    /**
     * @notice Initializer internal function for the Identity contract.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the ONCHAINID.
     */
    // solhint-disable-next-line func-name-mixedcase
    function _Identity_init(address initialManagementKey) internal {
        require(!initialized || _isConstructor(), "Initial key was already setup.");
        initialized = true;
        canInteract = true;

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

    
	
    /**
     * @notice Implementation of the getKey function from the ERC-734 standard
     *
     * @param key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
     *
     * @return purposes_ Returns the full key data, if present in the identity.
     * @return keyType_ Returns the full key data, if present in the identity.
     * @return key_ Returns the full key data, if present in the identity.
     */
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

    /**
    * @notice gets the purposes of a key
    *
    * @param key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
    *
    * @return purposes Returns the purposes of the specified key
    */
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

    /**
    * @notice gets all the keys with a specific purpose from an identity
    *
    * @param purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    *
    * @return keys Returns an array of public key bytes32 hold by this identity and having the specified purpose
    */
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

    /**
    * @notice implementation of the addKey function of the ERC-734 standard
    * Adds a key to the identity. The purpose specifies the purpose of key. Initially we propose four purposes:
    * 1: MANAGEMENT keys, which can manage the identity
    * 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
    * 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
    * 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
    * MUST only be done by keys of purpose 1, or the identity itself.
    * If its the identity itself, the approval process will determine its approval.
    *
    * @param key keccak256 representation of an ethereum address
    * @param keyType type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    * @param purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    *
    * @return success Returns TRUE if the addition was successful and FALSE if not
    */
    function addKey(
        bytes32 key,
        uint256 purpose,
        uint256 keyType
    )
        public
        delegatedOnly
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

    /**
    * @notice Remove the purpose from a key.
    */
    function removeKey(
        bytes32 key,
        uint256 purpose
    )
        public
        delegatedOnly
        override
        returns (bool success)
    {
        require(keys[key].key == key, "NonExisting: Key isn't registered");

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key"); // Sender has MANAGEMENTKEY
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


    /**
    * @notice Returns true if the key has MANAGEMENT purpose or the specified purpose.
    */
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


    /**
    * @notice Implementation of the addClaim function from the ERC-735 standard
    *  Require that the msg.sender has claim signer key.
    *
    * @param topic The type of claim
    * @param scheme The scheme with which this claim SHOULD be verified or how it should be processed.
    * @param issuer The issuers identity contract address, or the address used to sign the above signature.
    * @param signature Signature which is the proof that the claim issuer issued a claim of topic for this identity.
    * it MUST be a signed message of the following structure: keccak256(abi.encode(address identityHolder_address, uint256 _ topic, bytes data))
    * @param data The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
    * @param uri The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    *
    * @return claimRequestId Returns claimRequestId: COULD be send to the approve function, to approve or reject this claim.
    * triggers ClaimAdded event.
    */
    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
        public
        delegatedOnly
        override
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(issuer, topic));

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 3), "Permissions: Sender does not have claim signer key");
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

    /**
    * @notice Implementation of the removeClaim function from the ERC-735 standard
    * Require that the msg.sender has management key.
    * Can only be removed by the claim issuer, or the claim holder itself.
    *
    * @param claimId The identity of the claim i.e. keccak256(abi.encode(issuer, topic))
    *
    * @return success Returns TRUE when the claim was removed.
    * triggers ClaimRemoved event
    */
    function removeClaim(
        bytes32 claimId
    )
        public
        delegatedOnly
        override
        returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 3), "Permissions: Sender does not have CLAIM key");
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

    /**
    * @notice Implementation of the getClaim function from the ERC-735 standard.
    *
    * @param claimId The identity of the claim i.e. keccak256(abi.encode(issuer, topic))
    *
    * @return topic Returns all the parameters of the claim for the specified claimId (topic, scheme, signature, issuer, data, uri) .
    * @return scheme Returns all the parameters of the claim for the specified claimId (topic, scheme, signature, issuer, data, uri) .
    * @return issuer Returns all the parameters of the claim for the specified claimId (topic, scheme, signature, issuer, data, uri) .
    * @return signature Returns all the parameters of the claim for the specified claimId (topic, scheme, signature, issuer, data, uri) .
    * @return data Returns all the parameters of the claim for the specified claimId (topic, scheme, signature, issuer, data, uri) .
    * @return uri Returns all the parameters of the claim for the specified claimId (topic, scheme, signature, issuer, data, uri) .
    */
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

    /**
    * @notice Implementation of the getClaimIdsByTopic function from the ERC-735 standard.
    * used to get all the claims from the specified topic
    *
    * @param topic The identity of the claim i.e. keccak256(abi.encode(issuer, topic))
    *
    * @return claimIds Returns an array of claim IDs by topic.
    */
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

        // TODO check gnosis
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
    


    /*//////////////////////////////////////////////////////////////
                                EXECUTIONS
    //////////////////////////////////////////////////////////////*/

    
    
    /**
     * @notice Approves an execution or claim addition.
     * This SHOULD require n of m approvals of keys purpose 1, if the to of the execution is the identity contract itself, to successfully approve an execution.
     * And COULD require n of m approvals of keys purpose 2, if the to of the execution is another contract, to successfully approve an execution.
     */
    function approve(
        uint256 id,
        bool approve
    )
        public
        delegatedOnly
        override
        returns (bool success)
    {
        require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), "Sender does not have action key");

        emit Approved(id, approve);

        if (approve == true) {
            executions[id].approved = true;

            (success,) = executions[id].to.call{value:(executions[id].value)}(abi.encode(executions[id].data, 0));

            if (success) {
                executions[id].executed = true;

                emit Executed(
                    id,
                    executions[id].to,
                    executions[id].value,
                    executions[id].data
                );

                return true;
            } else {
                emit ExecutionFailed(
                    id,
                    executions[id].to,
                    executions[id].value,
                    executions[id].data
                );

                return false;
            }
        } else {
            executions[id].approved = false;
        }
        return true;
    }

    /**
     * @notice Passes an execution instruction to the keymanager.
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for addKey, removeKey and replaceKey and removeClaim.
     *
     * @return executionId SHOULD be sent to the approve function, to approve or reject this execution.
     */
    function execute(
        address to, 
        uint256 value, 
        bytes memory data
    )
        public
        delegatedOnly
        override
        payable
        returns (uint256 executionId)
    {
        uint256 executionId = _execute(to, value, data);
        return executionId;
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

        if (keyHasPurpose(keccak256(abi.encode(msg.sender)), 2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

}