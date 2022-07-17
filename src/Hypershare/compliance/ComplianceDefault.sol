// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IComplianceLimitHolder.sol';

contract ComplianceDefault is IComplianceLimitHolder, Ownable {

    // @dev Mapping between agents and their statuses
    mapping(uint256 => mapping(address => bool)) private _tokenAgentsList;

    // @dev Mapping from id to tokens linked to the compliance contract
    mapping(uint256 => bool) private _tokensBound;

    function isTokenAgent(
		address agentAddress,
		uint256 id
	)
		public
		view
		override
		returns (bool)
	{
        return (_tokenAgentsList[id][agentAddress]);
    }

    function addTokenAgent(
		address agentAddress,
		uint256 id
	)
		external
		override
		onlyOwner
	{
        require(!_tokenAgentsList[id][agentAddress], 'This Agent is already registered');
        _tokenAgentsList[id][agentAddress] = true;
        emit TokenAgentAdded(agentAddress);
    }

    function removeTokenAgent(
		address agentAddress,
        uint256 id
	)
		external
		override
		onlyOwner
	{
        require(_tokenAgentsList[id][agentAddress], 'This Agent is not registered yet');
        _tokenAgentsList[id][agentAddress] = false;
        emit TokenAgentRemoved(agentAddress);
    }

    function canTransfer(
        address /* _from */,
        address /* _to */,
        uint256 /* _value */
    ) external view override returns (bool) {
        return true;
    }

    function transferred(
        address /* _from */,
        address /* _to */,
        uint256 /* _value */
    ) external override {}

    function created(address /* _to */, uint256 /* _value */) external override {}

    function destroyed(address /* _from */, uint256 /* _value */) external override {}

    function transferOwnershipOnComplianceContract(
		address newOwner
	)
		external
		override
		onlyOwner
	{
        transferOwnership(newOwner);
    }
}