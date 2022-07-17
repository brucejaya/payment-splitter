/* SPDX-License-Identifier: MIT */

pragma solidity 0.8.0;

import './IdentityRegistry.sol';

contract IdentityDelegates is IdentityRegistry {
	
    uint256 MANAGEMENT_KEY = 1;
    uint256 ACTION_KEY = 2;
    uint256 CLAIM_KEY = 3;
    uint256 ENCRYPTION_KEY = 4;

    struct Delegate {
        mapping(uint256 => bool) permissionExists;
        uint256[] permissions; //e.g., MANAGEMENT_KEY = 1, ACTION_KEY = 2, etc.
        uint256 delegateType; // e.g. 1 = ECDSA, 2 = RSA, etc. ??  TODO Contract signature? 
    }
    
    event DelegateAdded(bytes32 indexed identity, bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event DelegateRemoved(bytes32 indexed identity, bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

	mapping(bytes32 => mapping(bytes32 => Delegate)) public delegates; // i.e., The public key. For non-hex and long delegates, its the Keccak256 hash of the key
	mapping(bytes32 => bytes32[]) public delegateList;
    mapping(bytes32 => bytes32) delegateIdentity; // Delegate => Identity

    function delegateIsIdentity(bytes32 _identity, address _delegateAddress)
        public
        view
        returns (bool exists)
    {
        bytes32 delegate = addressToBytes32(_delegateAddress);
        for (uint256 i = 0; i < delegateIdentity[_identity].length; i++) {
            if (delegateIdentity[_identity] == delegate) {
                return true;
            }
        }
        return false;
    }
    
    
    function getIdentityByDelegate(address _delegateAddress)
        public
        view
        returns (bytes32 identity)
    {
        return delegateIdentity[addressToBytes32(_delegateAddress)];
    }
    

    function getDelegate(bytes32 _identity, bytes32 _delegate)
        public
        view
        returns(uint256[] memory permissions, uint256 delegateType, bytes32 key)
    {
        return (delegates[_identity][_delegate].permissions, delegates[_identity][_delegate].delegateType, _delegate);
    }


    function delegateHasPermission(bytes32 _identity, bytes32 _delegate, uint256 purpose)
		public
		view
		returns(bool exists)
	{
        return delegates[_identity][_delegate].permissionExists[purpose];
    }


    function getDelegatesByPurpose(bytes32 _identity, uint256 _permission)
		public
		returns(bytes32[] memory _delegates)
	{
        // i think its cheaper to have a 2 memory array then to use storage
        // and because this function is mainly meant for read permissions only
        uint256[] memory foundKeysIndex = new uint256[](delegateList[_identity].length);

        uint256 foundKeyCount = 0;
        for (uint256 x = 0; x < delegateList[_identity].length; x++) {
            if (delegates[delegateList[_identity][x]].permissionExists[_permission]) {
                foundKeysIndex[foundKeyCount] = x;
                foundKeyCount++;
            }
        }
        _delegates = new bytes32[](foundKeyCount);

        for (uint256 ii = 0; ii < foundKeyCount; ii++) {
            _delegates[ii] = delegateList[_identity][foundKeysIndex[ii]];
        }
    }

	function addDelegate(bytes32 _identity, uint256 _permission, uint256 _delegateType, bytes32 _delegate)
		public
        returns(bool success)
    {
		
        require(!delegates[_identity][_delegate].permissionExists[_permission]);
        require(delegates[_identity][_delegate].delegateType == 0 || delegates[_identity][_delegate].delegateType == _delegateType);

        delegates[_identity][_delegate].permissions.push(_permission);
        delegates[_identity][_delegate].delegateType = _delegateType;
        delegates[_identity][_delegate].permissionExists[_permission] = true;
        delegateList[_identity].push(_delegate);


		emit DelegateAdded(_identity, _delegate, _permission, _delegateType);

        return true;
	}

	
    function removeDelegate(bytes32 _identity, uint256 _permission, bytes32 _delegate)
        public 
		returns(bool success)
    {
        require(delegates[_identity][_delegate].permissionExists[_permission], "Purpose does not exist for this key");

        Delegate storage delegateToRemove = delegates[_identity][_delegate];

        // find the correct one in the array and delete the purpose
        for (uint256 i = 0; i < delegateToRemove.permissions.length; i++) {
            if (delegateToRemove.permissions[i] == _permission) {
                if (delegateToRemove.permissions.length > 1) {
                    delegateToRemove.permissions[i] = delegateToRemove.permissions[delegateToRemove.permissions.length - 1];
                }
                delete delegateToRemove.permissions[delegateToRemove.permissions.length - 1];
                delegateToRemove.permissions.length--;

                break;
            }
        }
        delegateToRemove.permissionExists[_permission] = false;

        if (delegateToRemove.permissions.length == 0) {
            // remove delegateType
            delete delegateToRemove.delegateType;
            // remove the _delegate from keylist[_identity] if all the purpose were deleted
            for (uint256 ii = 0; ii < delegateList[_identity].length; ii++) {
                if (delegateList[_identity][ii] == _delegate) {
                    if (delegateList[_identity].length > 1) {
                        delegateList[_identity][ii] = delegateList[_identity][delegateList[_identity].length - 1];
                    }
                    delete delegateList[_identity][ii];
                    delegateList[_identity].length--;
                    break;
                }
            }
        }

        require(delegateList[_identity].length > 0); // don't remove the last key
		emit DelegateAdded(_identity, _delegate, _permission, delegateToRemove.delegateType);

        return true;
    }

}
