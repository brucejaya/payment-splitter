// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../Roles.sol';

// ! Roles seems to deal exclusively with contract upgrades

contract OwnerRoles is Ownable {

    using Roles for Roles.Role;

    ////////////////
    // EVENTS
    ////////////////

    event RoleAdded(address indexed _owner, string _role);
    event RoleRemoved(address indexed _owner, string _role);

    ////////////////
    // ROLES
    ////////////////

    Roles.Role private _ownerAdmin;
    Roles.Role private _registryAddressSetter;
    Roles.Role private _complianceSetter;
    Roles.Role private _complianceManager;
    Roles.Role private _claimRegistryManager;
    Roles.Role private _issuersRegistryManager;

    ////////////////
    // MODIFIERS
    ////////////////

    modifier onlyAdmin() {
        require(owner() == msg.sender || isOwnerAdmin(_msgSender()), 'Role: Sender is NOT Admin');
        _;
    }

    function isOwnerAdmin(address _owner) public view returns (bool) {
        return _ownerAdmin.has(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    function addOwnerAdmin(address _owner) external onlyAdmin {
        _ownerAdmin.add(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleAdded(_owner, _role);
    }

    function removeOwnerAdmin(address _owner) external onlyAdmin {
        _ownerAdmin.remove(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleRemoved(_owner, _role);
    }
    
    /*//////////////////////////////////////////////////////////////
                            REGISTRY ADDRESS ???
    //////////////////////////////////////////////////////////////*/

    function isRegistryAddressSetter(address _owner) public view returns (bool) {
        return _registryAddressSetter.has(_owner);
    }

    function addRegistryAddressSetter(address _owner) external onlyAdmin {
        _registryAddressSetter.add(_owner);
        string memory _role = 'RegistryAddressSetter';
        emit RoleAdded(_owner, _role);
    }

    function removeRegistryAddressSetter(address _owner) external onlyAdmin {
        _registryAddressSetter.remove(_owner);
        string memory _role = 'RegistryAddressSetter';
        emit RoleRemoved(_owner, _role);
    }
    
    /*//////////////////////////////////////////////////////////////
                              COMPLIANCE
    //////////////////////////////////////////////////////////////*/

    function isComplianceSetter(address _owner) public view returns (bool) {
        return _complianceSetter.has(_owner);
    }

    function addComplianceSetter(address _owner) external onlyAdmin {
        _complianceSetter.add(_owner);
        string memory _role = 'ComplianceSetter';
        emit RoleAdded(_owner, _role);
    }

    function removeComplianceSetter(address _owner) external onlyAdmin {
        _complianceSetter.remove(_owner);
        string memory _role = 'ComplianceSetter';
        emit RoleRemoved(_owner, _role);
    }

    /*//////////////////////////////////////////////////////////////
                            COMPLIANCE MANAGER
    //////////////////////////////////////////////////////////////*/

    function isComplianceManager(address _owner) public view returns (bool) {
        return _complianceManager.has(_owner);
    }

    function addComplianceManager(address _owner) external onlyAdmin {
        _complianceManager.add(_owner);
        string memory _role = 'ComplianceManager';
        emit RoleAdded(_owner, _role);
    }

    function removeComplianceManager(address _owner) external onlyAdmin {
        _complianceManager.remove(_owner);
        string memory _role = 'ComplianceManager';
        emit RoleRemoved(_owner, _role);
    }
    
    /*//////////////////////////////////////////////////////////////
                            CLAIM REGISTRY
    //////////////////////////////////////////////////////////////*/
    
    function isClaimRegistryManager(address _owner) public view returns (bool) {
        return _claimRegistryManager.has(_owner);
    }

    function addClaimRegistryManager(address _owner) external onlyAdmin {
        _claimRegistryManager.add(_owner);
        string memory _role = 'ClaimRegistryManager';
        emit RoleAdded(_owner, _role);
    }

    function removeClaimRegistryManager(address _owner) external onlyAdmin {
        _claimRegistryManager.remove(_owner);
        string memory _role = 'ClaimRegistryManager';
        emit RoleRemoved(_owner, _role);
    }
    
    /*//////////////////////////////////////////////////////////////
                         VERIFIERS REGISTRY
    //////////////////////////////////////////////////////////////*/

    function isVerifiersRegistryManager(address _owner) public view returns (bool) {
        return _issuersRegistryManager.has(_owner);
    }

    function addVerifiersRegistryManager(address _owner) external onlyAdmin {
        _issuersRegistryManager.add(_owner);
        string memory _role = 'VerifiersRegistryManager';
        emit RoleAdded(_owner, _role);
    }

    function removeVerifiersRegistryManager(address _owner) external onlyAdmin {
        _issuersRegistryManager.remove(_owner);
        string memory _role = 'VerifiersRegistryManager';
        emit RoleRemoved(_owner, _role);
    }

}