/* SPDX-License-Identifier: MIT */

pragma solidity 0.8.6;

// Y manages key management

contract B is A {
	
    uint256 MANAGEMENT_KEY = 1;
    uint256 ACTION_KEY = 2;
    uint256 CLAIM_SIGNER_KEY = 3;
    uint256 ENCRYPTION_KEY = 4;

    event KeyAdded(bytes32 identity, bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 identity, bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(bytes32 identity, uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(bytes32 identity, uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(bytes32 identity, uint256 indexed executionId, bool approved);

    struct Key {
        mapping(uint256 => bool) purposeExists;
        uint256[] purposes; //e.g., MANAGEMENT_KEY = 1, ACTION_KEY = 2, etc.
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        // note the bytes32 key has been removed since we could use mapping key as the key identifier
    }

	mapping(bytes32 => mapping(bytes32 => Key)) public keys; // i.e., The public key. For non-hex and long keys, its the Keccak256 hash of the key
	mapping(bytes32 => bytes32[]) public keyList;


	// *** PUBLIC FUNCTIONS *** //

    function addressToBytes32(address toCast)
        public
        pure
        returns(bytes32 key)
    {
        return bytes32(toCast);
    }
	
    function getKey(bytes32 _identity, bytes32 _key)
        public
        view
        returns(uint256[] purposes, uint256 keyType, bytes32 key)
    {
        return (keys[_identity][_key].purposes, keys[_identity][_key].keyType, _key);
    }


    function keyHasPurpose(bytes32 _identity, bytes32 _key, uint256 purpose)
		public
		view
		returns(bool exists)
	{
        return keys[_identity][_key].purposeExists[purpose];
    }


    function getKeysByPurpose(bytes32 _identity, uint256 _purpose)
		public
		returns(bytes32[] _keys)
	{
        // i think its cheaper to have a 2 memory array then to use storage
        // and because this function is mainly meant for read purposes only
        uint256[] memory foundKeysIndex = new uint256[](keyList[_identity].length);

        uint256 foundKeyCount = 0;
        emit test(keyList[_identity].length, true);
        for (uint256 i = 0; i < keyList[_identity].length; i++) {
            if (keys[keyList[_identity][i]].purposeExists[_purpose]) {
                foundKeysIndex[foundKeyCount] = i;
                foundKeyCount++;
            }
        }
        _keys = new bytes32[](foundKeyCount);

        for (uint256 j = 0; j < foundKeyCount; j++) {
            _keys[j] = keyList[_identity][foundKeysIndex[j]];
        }
    }

	function addKey(bytes32 _identity, uint256 _purpose, uint256 _keyType, bytes32 _key)
		public
        returns(bool success)
    {
		
        require(!keys[_identity][_key].purposeExists[_purpose]);
        require(keys[_identity][_key].keyType == 0 || keys[_identity][_key].keyType == _keyType);

        keys[_identity][_key].purposes.push(_purpose);
        keys[_identity][_key].keyType = _keyType;
        keys[_identity][_key].purposeExists[_purpose] = true;
        keyList[_identity].push(_key);

        emit KeyAdded(_key, _purpose, _keyType);
		emit KeyAdded(_identity, _key, _purpose, _keyType);

        return true;
	}

	
    function removeKey(bytes32 _identity, uint256 _purpose, bytes32 _key)
        public 
		returns(bool success)
    {
        require(keys[_identity][_key].purposeExists[_purpose], "Purpose does not exist for this key");

        Key storage keyToRemove = keys[_identity][_key];

        // find the correct one in the array and delete the purpose
        for (uint256 i = 0; i < keyToRemove.purposes.length; i++) {
            if (keyToRemove.purposes[i] == _purpose) {
                if (keyToRemove.purposes.length > 1) {
                    keyToRemove.purposes[i] = keyToRemove.purposes[keyToRemove.purposes.length - 1];
                }
                delete keyToRemove.purposes[keyToRemove.purposes.length - 1];
                keyToRemove.purposes.length--;

                break;
            }
        }
        keyToRemove.purposeExists[_purpose] = false;

        if (keyToRemove.purposes.length == 0) {
            // remove keyType
            delete keyToRemove.keyType;
            // remove the _key from keylist[_identity] if all the purpose were deleted
            for (uint256 j = 0; j < keyList[_identity].length; j++) {
                if (keyList[_identity][j] == _key) {
                    if (keyList[_identity].length > 1) {
                        keyList[_identity][i] = keyList[_identity][keyList[_identity].length - 1];
                    }
                    delete keyList[_identity][j];
                    keyList[_identity].length--;
                    break;
                }
            }
        }

        require(keyList[_identity].length > 0); // don't remove the last key
        emit KeyRemoved(_key, _purpose, keyToRemove.keyType);
        return true;
    }

}
