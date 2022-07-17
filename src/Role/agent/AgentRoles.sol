// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../Roles.sol';

// !    Roles seems to basically all be redundant, no need to for such complex control structures, surely
// !    Could this all be refactored to as to more directly mimic the ERC-734 key manager
// !    This could be the basis for HyperDAC

contract AgentRoles is Ownable {

    using Roles for Roles.Role;

    event RoleAdded(address indexed _agent, string _role);
    event RoleRemoved(address indexed _agent, string _role);

    Roles.Role private _supplyModifiers;
    Roles.Role private _freezers;
    Roles.Role private _transferManagers;
    Roles.Role private _recoveryAgents;
    Roles.Role private _complianceAgents;
    Roles.Role private _whiteListManagers;
    Roles.Role private _agentAdmin;

    modifier onlyAdmin() {
        require(owner() == msg.sender || isAgentAdmin(_msgSender()), 'Role: Sender is NOT Admin');
        _;
    }

    /// @dev AgentAdmin Role _agentAdmin
    function isAgentAdmin(
        address _agent
    )
        public
        view
        returns (bool)
    {
        return _agentAdmin.has(_agent);
    }

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

    /// @dev SupplyModifier Role _supplyModifiers
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