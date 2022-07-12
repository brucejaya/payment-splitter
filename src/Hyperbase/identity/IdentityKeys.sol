// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract IdentityKeys {
	
    mapping(bytes32 => Key) internal keys;
    mapping(uint256 => bytes32[]) internal keysByPurpose;
	
   /**
    * @dev Definition of the structure of a Key.
    *
    * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
    * The structure should be as follows:
    *   - key: A public key owned by this identity
    *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
    *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
    */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }
	
    /**
     * @notice Implementation of the getKey function from the ERC-734 standard
     *
     * @param key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
     *
     * @return purposes Returns the full key data, if present in the identity.
     * @return keyType Returns the full key data, if present in the identity.
     * @return key Returns the full key data, if present in the identity.
     */
    function getKey(
        bytes32 key
    )
        public
        override
        view
        returns(uint256[] memory purposes, uint256 keyType, bytes32 key)
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
    * @param type type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    * @param purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    *
    * @return success Returns TRUE if the addition was successful and FALSE if not
    */
    function addKey(
        bytes32 key,
        uint256 purpose,
        uint256 type
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
            keys[key].keyType = type;
        }

        keysByPurpose[purpose].push(key);

        emit KeyAdded(key, purpose, type);

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

}