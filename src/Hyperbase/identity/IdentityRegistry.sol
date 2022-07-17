// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IClaimValidator.sol';
import '../../Interface/IIdentity.sol';

import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';

// TODO replace owner role with ownable or operatorApprovals?

contract IdentityRegistry is IIdentityRegistry {

    // @dev mapping between a user address and the corresponding identity
    mapping(address => Identity) private identities;

   // @dev struct containing the identity contract and the country of the user
    struct Identity {
        IIdentity identityContract;
        uint16 identityCountry;
    }

    // @dev the constructor initiates the Identity Registry smart contract
    // constructor(
    // ) {
    // }

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
                            IDENTITY CONTROLS
    //////////////////////////////////////////////////////////////*/

    function registerIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country
    )
        public
        override
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
    {
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
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
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
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
        require(_account == _msgSender(), "Only the owner of an identity can make changes to it");
        identityRegistryStorage_.removeIdentityFromStorage(_account);
        emit IdentityRemoved(_account, identity(_account));
    }

    /*//////////////////////////////////////////////////////////////
                                FACTORY 
    //////////////////////////////////////////////////////////////*/


    // TODO, factory



    /*//////////////////////////////////////////////////////////////
                             HYPERSURFACE
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(
        address _newOwner
    )
        external
        override
        onlyOwner
    {
        transferOwnership(_newOwner);
    }

}
