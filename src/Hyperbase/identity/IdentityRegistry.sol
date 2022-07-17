// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IClaimValidator.sol';
import '../../Interface/IIdentity.sol';

import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IIdentityRegistryStorage.sol';

// TODO replace owner role with ownable or operatorApprovals?
// import '../../HyperDAC/owner/OwnerRoles.sol';

contract IdentityRegistry is IIdentityRegistry /*, OwnerRole */ {

    // @dev Address of the IdentityRegistryStorage Contract
    IIdentityRegistryStorage private identityRegistryStorage_;

    // @dev Address of the ComplianceClaimsRequired Contract
    IComplianceClaimsRequired private complianceClaimsRequired_;

    // @dev Address of the ClaimVerifiersRegistry Contract
    IClaimVerifiersRegistry private claimVerifiersRegistry_;

    // @dev the constructor initiates the Identity Registry smart contract
    constructor(
        address _claimVerifiersRegistry,
        address _complianceClaimsRequired,
        address _identityRegistryStorage
    ) {
        complianceClaimsRequired_ = IComplianceClaimsRequired(_complianceClaimsRequired);
        claimVerifiersRegistry_ = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        identityRegistryStorage_ = IIdentityRegistryStorage(_identityRegistryStorage);
        emit ComplianceClaimsRequiredSet(_complianceClaimsRequired);
        emit ClaimVerifiersRegistrySet(_claimVerifiersRegistry);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // @dev returns the associated address of an identity account
    function identity(
        address _account
    )
        public
        view
        override
        returns (IIdentity)
    {
        return identityRegistryStorage_.storedIdentity(_account);
    }

    function identityCountry(
        address _account
    )
        external
        view
        override
        returns (uint16)
    {
        return identityRegistryStorage_.storedHolderCountry(_account);
    }

    function claimVerifiersRegistry()
        external
        view
        override
        returns (IClaimVerifiersRegistry)
    {
        return claimVerifiersRegistry_;
    }
    function claimRegistry()
        external
        view
        override
        returns (IClaimVerifiersRegistry)
    {
        return claimRegistry_;
    }

    function complianceClaimsRequired()
        external
        view
        override
        returns (IComplianceClaimsRequired)
    {
        return complianceClaimsRequired_;
    }

    function identityRegistryStorage()
        external
        view
        override
        returns (IIdentityRegistryStorage)
    {
        return identityRegistryStorage_;
    }

    function contains(
        address _account
    )
        external
        view
        override
        returns (bool)
    {
        if (address(identity(_account)) == address(0)) {
            return false;
        }
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                                 AGENT
    //////////////////////////////////////////////////////////////*/

    /*
    function addAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        override
    {
        addAgent(_agent);
    }

    function removeAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        override
    {
        removeAgent(_agent);
    }

    */

    /*//////////////////////////////////////////////////////////////
                                CONTRACTS
    //////////////////////////////////////////////////////////////*/

    function setIdentityRegistryStorage(
        address _identityRegistryStorage
    )
        external
        override
        onlyOwner
    {
        identityRegistryStorage_ = IIdentityRegistryStorage(_identityRegistryStorage);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    function setComplianceClaimsRequired(
        address _complianceClaimsRequired
    )
        external
        override
        onlyOwner
    {
        complianceClaimsRequired_ = IComplianceClaimsRequired(_complianceClaimsRequired);
        emit ComplianceClaimsRequiredSet(_complianceClaimsRequired);
    }

    function setClaimVerifiersRegistry(
        address _claimVerifiersRegistry
    )
        external
        override
        onlyOwner
    {
        claimVerifiersRegistry_ = IClaimVerifiersRegistry(_claimVerifiersRegistry);
        emit ClaimVerifiersRegistrySet(_claimVerifiersRegistry);
    }

        function transferOwnershipOnIdentityRegistryContract(
        address _newOwner
    )
        external
        override
        onlyOwner
    {
        transferOwnership(_newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                            IDENTITY CONTROLS
    //////////////////////////////////////////////////////////////*/

    function registerIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country
    )
        public
        override
        onlyAgent
    {
        identityRegistryStorage_.addIdentityToStorage(_account, _identity, _country);
        emit IdentityRegistered(_account, _identity);
    }

    function batchRegisterIdentity(
        address[] calldata _accounts,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    )
        external
        override
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            registerIdentity(_accounts[i], _identities[i], _countries[i]);
        }
    }

    // @dev updates the country associated with an identity account
    function updateIdentity(
        address _account,
        IIdentity _identity
    )
        external
        override
        onlyAgent
    {
        IIdentity oldIdentity = identity(_account);
        identityRegistryStorage_.modifyStoredIdentity(_account, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    // @dev updates the country associated with an identity account
    function updateCountry(
        address _account, 
        uint16 _country
    )
        external
        override
        onlyAgent
    {
        identityRegistryStorage_.modifyStoredHolderCountry(_account, _country);
        emit CountryUpdated(_account, _country);
    }
    
    // @dev removes an identity from the registry
    function deleteIdentity(
        address _account
    )
        external
        override
        onlyAgent
    {
        identityRegistryStorage_.removeIdentityFromStorage(_account);
        emit IdentityRemoved(_account, identity(_account));
    }

    /*//////////////////////////////////////////////////////////////
                                FACTORY 
    //////////////////////////////////////////////////////////////*/


    // TODO, factory


}
