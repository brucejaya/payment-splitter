/* SPDX-License-Identifier: MIT */

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import './IdentityDelegates.sol';


contract IdentityEnforcer is Context, IdentityDelegates {
	
    /**
     * @dev Throws if called by any account other than an identity delegate with management permissions.
     */
    modifier onlyManagement(address identity) {
        require(delegateHasPermission(identity, _msgSender(), MANAGEMENT_KEY), "Ownable: caller does not have management permissions");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than an identity delegate with action permissions.
     */
    modifier onlyAction(address identity) {
        require(delegateHasPermission(identity, _msgSender(), ACTION_KEY), "Ownable: caller does not have action permissions");
        _;
    }

    /**
     * @dev Throws if called by any account other than an identity delegate with encryption permissions.
     */
    modifier onlyEncryption(address identity) {
        require(delegateHasPermission(identity, _msgSender(), ENCRYPTION_KEY), "Ownable: caller does not have encryption permissions");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than an identity delegate with claim permissions.
     */
    modifier onlyClaim(address identity) {
        require(delegateHasPermission(identity, _msgSender(), CLAIM_KEY), "Ownable: caller does not have encryption permissions");
        _;
    }
}