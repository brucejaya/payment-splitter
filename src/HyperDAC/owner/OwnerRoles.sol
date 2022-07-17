// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './Roles.sol';

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

contract OwnerRoles is Ownable {

    ////////////////
    // EVENTS
    ////////////////

    event RoleAdded(address indexed _owner, string _role);
    event RoleRemoved(address indexed _owner, string _role);

    ////////////////
    // ROLES
    ////////////////

    // @dev Owner roles
    Roles.Role private _ownerAdmin;
    Roles.Role private _registryAddressSetter;
    Roles.Role private _complianceSetter;
    Roles.Role private _complianceManager;
    Roles.Role private _claimRegistryManager;
    Roles.Role private _issuersRegistryManager;

    // @agent roles 
    Roles.Role private _supplyModifiers;
    Roles.Role private _freezers;
    Roles.Role private _transferManagers;
    Roles.Role private _recoveryAgents;
    Roles.Role private _complianceAgents;
    Roles.Role private _whiteListManagers;
    Roles.Role private _agentAdmin;


    ////////////////
    // MODIFIERS
    ////////////////

    modifier onlyAdmin() {
        require(owner() == msg.sender || isOwnerAdmin(_msgSender()), 'Role: Sender is NOT Admin');
        _;
    }

    modifier onlyAgent() {
        require(isAgent(msg.sender), 'AgentRole: caller does not have the Agent role');
        _;
    }

    // @dev OwnerAdmin Role _ownerAdmin
    function isOwnerAdmin(
        address _owner
    )
        public
        view
        returns (bool)
    {
        return _ownerAdmin.has(_owner);
    }

    
    // @dev AgentAdmin Role _agentAdmin
    function isAgentAdmin(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _agentAdmin.has(_agent);
    }

    
    function isAgent(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _agents.has(_agent);
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER ADMIN
    //////////////////////////////////////////////////////////////*/

    function addOwnerAdmin(
        address _owner
    )
        external
        onlyAdmin
    {
        _ownerAdmin.add(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleAdded(_owner, _role);
    }

    function removeOwnerAdmin(
        address _owner
    )
        external
        onlyAdmin
    {
        _ownerAdmin.remove(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleRemoved(_owner, _role);
    }

    /*//////////////////////////////////////////////////////////////
                              AGENT ADMIN
    //////////////////////////////////////////////////////////////*/

    function addAgentAdmin(
        address _agent
    ) 
        external
        onlyAdmin
    {
        _agentAdmin.add(_agent);
        string memory _role = 'AgentAdmin';
        emit RoleAdded(_agent, _role);
    }

    function removeAgentAdmin(
        address _agent
    )
        external 
        onlyAdmin 
    {
        _agentAdmin.remove(_agent);
        string memory _role = 'AgentAdmin';
        emit RoleRemoved(_agent, _role);
    }

    /*//////////////////////////////////////////////////////////////
                                AGENT
    //////////////////////////////////////////////////////////////*/

    function addAgent(address _agent) public onlyOwner {
        _agents.add(_agent);
        emit AgentAdded(_agent);
    }

    function removeAgent(address _agent) public onlyOwner {
        _agents.remove(_agent);
        emit AgentRemoved(_agent);
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


    /*//////////////////////////////////////////////////////////////
                         SUPPLY MODIFIER
    //////////////////////////////////////////////////////////////*/

    // @dev SupplyModifier Role _supplyModifiers
    function isSupplyModifier(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _supplyModifiers.has(_agent);
    }

    function addSupplyModifier(
        address _agent
    )
        external
        onlyAdmin
    {
        _supplyModifiers.add(_agent);
        string memory _role = 'SupplyModifier';
        emit RoleAdded(_agent, _role);
    }

    function removeSupplyModifier(
        address _agent
    )
        external
        onlyAdmin
    {
        _supplyModifiers.remove(_agent);
        string memory _role = 'SupplyModifier';
        emit RoleRemoved(_agent, _role);
    }

    /*//////////////////////////////////////////////////////////////
                                FREEZE
    //////////////////////////////////////////////////////////////*/

    /// @dev Freezer Role _freezers
    function isFreezer(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _freezers.has(_agent);
    }

    function addFreezer(
        address _agent
    )
        external
        onlyAdmin
    {
        _freezers.add(_agent);
        string memory _role = 'Freezer';
        emit RoleAdded(_agent, _role);
    }

    function removeFreezer(
        address _agent
    )
        external
        onlyAdmin
    {
        _freezers.remove(_agent);
        string memory _role = 'Freezer';
        emit RoleRemoved(_agent, _role);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER MANAGER
    //////////////////////////////////////////////////////////////*/

    /// @dev TransferManager Role _transferManagers
    function isTransferManager(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _transferManagers.has(_agent);
    }

    function addTransferManager(
        address _agent
    )
        external
        onlyAdmin
    {
        _transferManagers.add(_agent);
        string memory _role = 'TransferManager';
        emit RoleAdded(_agent, _role);
    }

    function removeTransferManager(
        address _agent
    )
        external
        onlyAdmin
    {
        _transferManagers.remove(_agent);
        string memory _role = 'TransferManager';
        emit RoleRemoved(_agent, _role);
    }


    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/

    /// @dev RecoveryAgent Role _recoveryAgents
    function isRecoveryAgent(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _recoveryAgents.has(_agent);
    }

    function addRecoveryAgent(
        address _agent
    )
        external
        onlyAdmin
    {
        _recoveryAgents.add(_agent);
        string memory _role = 'RecoveryAgent';
        emit RoleAdded(_agent, _role);
    }

    function removeRecoveryAgent(
        address _agent
    ) external onlyAdmin {
        _recoveryAgents.remove(_agent);
        string memory _role = 'RecoveryAgent';
        emit RoleRemoved(_agent, _role);
    }
    
    /*//////////////////////////////////////////////////////////////
                              COMPLIANCE
    //////////////////////////////////////////////////////////////*/


    /// @dev ComplianceAgent Role _complianceAgents
    function isComplianceAgent(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _complianceAgents.has(_agent);
    }

    function addComplianceAgent(
        address _agent
    ) 
        external 
        onlyAdmin 
    {
        _complianceAgents.add(_agent);
        string memory _role = 'ComplianceAgent';
        emit RoleAdded(_agent, _role);
    }

    function removeComplianceAgent(
        address _agent
    ) 
        external 
        onlyAdmin 
    {
        _complianceAgents.remove(_agent);
        string memory _role = 'ComplianceAgent';
        emit RoleRemoved(_agent, _role);
    }

    /*//////////////////////////////////////////////////////////////
                                WHITELIST
    //////////////////////////////////////////////////////////////*/

    /// @dev WhiteListManager Role _whiteListManagers
    function isWhiteListManager(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _whiteListManagers.has(_agent);
    }

    function addWhiteListManager(
        address _agent
    )
        external
        onlyAdmin
    {
        _whiteListManagers.add(_agent);
        string memory _role = 'WhiteListManager';
        emit RoleAdded(_agent, _role);
    }

    function removeWhiteListManager(
        address _agent
    )
        external
        onlyAdmin
    {
        _whiteListManagers.remove(_agent);
        string memory _role = 'WhiteListManager';
        emit RoleRemoved(_agent, _role);
    }


}