// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IOrganisationManaged.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';

contract OrganisationManaged is IOrganisationManaged, Context {

    ////////////////
    // CONSTANTS
    ////////////////

    // TODO, restructure these so as to be more relevant...
   
    // @dev Super user privileges
    uint256 constant MANAGEMENT = 1;

    // @dev Setter roles
    uint256 constant REGISTRY_ADDRESS_SETTER = 2;
    uint256 constant COMPLIANCE_SETTER = 3;

    // @dev Manager roles
    uint256 constant COMPLIANCE_MANAGER = 4;
    uint256 constant CLAIMS_REGISTRY_MANAGEr = 5;
    uint256 constant ISSUER_REGISTRY_MANAGER = 6;

    // @dev token controls 
    uint256 constant SUPPLY_MODIFIER = 7;
    uint256 constant FREEZERS = 8;
    uint256 constant TRANSFER_MANAGER = 9;
    uint256 constant RECOVERY_AGENTS = 10;
    uint256 constant COMPLIANCE_AGENTS = 11;
    uint256 constant WHITELIST_MANAGERS = 12;
    uint256 constant AGENT_ADMIN = 13;

    ////////////////
    // STORAGE
    ////////////////

    mapping(address => Operator) internal operators;
    mapping(uint256 => address[]) internal operatorsByRole;

    struct Operator {
        bool exists;
        uint256[] roles;
    }

    ////////////////
    // CONSTRUCTOR
    ////////////////
  
    function init(
        address account
    )
        internal
    {
        addOperator(account, MANAGEMENT);
    }

    // TODO 
    // function MultiSigWallet(address[] _owners, uint _required)
    //     public
    //     validRequirement(_owners.length, _required)
    // {
    //     for (uint i=0; i<_owners.length; i++) {
    //         require(!isOwner[_owners[i]] && _owners[i] != 0);
    //         isOwner[_owners[i]] = true;
    //     }
    //     owners = _owners;
    //     required = _required;
    // }


    ////////////////
    // MODIFIERS
    ////////////////
    
    modifier onlyRole(
        uint256 role
    ) {
        require(operatorHasRole(_msgSender(), role), 'Role: Sender does have the appropriate role');
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function getOperator(
        address account
    )
        public
        override
        view
        returns(uint256[] memory role_)
    {
        return (operators[account].roles);
    }

    function getOperatorRoles(
        address account
    )
        public
        override
        view
        returns(uint256[] memory roles)
    {
        return (operators[account].roles);
    }

    function getOperatorsByRole(
        uint256 role
    )
        public
        override
        view
        returns(bytes32[] memory operators)
    {
        return operatorsByRole[role];
    }
    
    // @dev Returns true if operator has role.
    function operatorHasRole(
        address account, 
        uint256 role
    )
        public
        override
        view
        returns(bool result)
    {
        Operator memory operator = operators[account];
        if (!operator.exists) return false;
        for (uint operatorRoleIndex = 0; operatorRoleIndex < operator.roles.length; operatorRoleIndex++) {
            uint256 role = operator.roles[operatorRoleIndex];

            if (role == 1 || role == role) return true;
        }
        return false;
    }
    
    /*//////////////////////////////////////////////////////////////
                             ADD/REMOVE
    //////////////////////////////////////////////////////////////*/
    
    // @dev If operator exists, add new role. Otherwise creates an operator with role from scratch.
    function addOperator(
        address account,
        uint256 role
    )
        public
        override
        returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(operatorHasRole(msg.sender, MANAGEMENT), "Permissions: Sender does not have management operator");
        }
        if (operators[account].exists) {
            for (uint operatorRoleIndex = 0; operatorRoleIndex < operators[account].roles.length; operatorRoleIndex++) {
                uint256 role = operators[account].roles[operatorRoleIndex];
                if (role == role) {
                    revert("Conflict: Operator already has role");
                }
            }
            operators[account].roles.push(role);
        }
        else {
            operators[account].exists = true;
            operators[account].roles.push(role);
        }
        operatorsByRole[role].push(account);
        emit OperatorAdded(account, role);
        return true;
    }

    function removeOperator(
        address account,
        uint256 role
    )
        public
        override
        returns (bool success)
    {
        require(operators[account].exists, "NonExisting: Operator isn't registered");
        if (msg.sender != address(this)) {
            require(operatorHasRole(msg.sender, MANAGEMENT), "Permissions: Sender does not have management operator");
        }
        require(operators[account].roles.length > 0, "NonExisting: Operator doesn't have such role");
        uint roleIndex = 0;
        while (operators[account].roles[roleIndex] != role) {
            roleIndex++;
            if (roleIndex >= operators[account].roles.length) {
                break;
            }
        }
        require(roleIndex < operators[account].roles.length, "NonExisting: Operator doesn't have such role");
        operators[account].roles[roleIndex] = operators[account].roles[operators[account].roles.length - 1];
        operators[account].roles.pop();
        uint operatorIndex = 0;
        while (operatorsByRole[role][operatorIndex] != account) {
            operatorIndex++;
        }
        operatorsByRole[role][operatorIndex] = operatorsByRole[role][operatorsByRole[role].length - 1];
        operatorsByRole[role].pop();
        uint operatorType = operators[account].existsType;
        if (operators[account].roles.length == 0) {
            delete operators[account];
        }
        emit OperatorRemoved(account, role);
        return true;
    }

}