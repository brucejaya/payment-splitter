// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IComplianceTokenRegistry.sol';

contract ComplianceTokenRegistryDefault is IComplianceTokenRegistry, Ownable {

    /// @dev Mapping between agents and their statuses
    mapping(address => bool) private _tokenAgentsList;

    /// @dev Mapping from id to tokens linked to the compliance contract
    mapping(uint256 => bool) private _tokensBound;

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function isTokenAgent(address _agentAddress) public view override returns (bool) {
        return (_tokenAgentsList[_agentAddress]);
    }

    /**
     *  @dev See {ICompliance-isTokenBound}.
     */
    function isTokenBound(uint256 _id) public view override returns (bool) {
        return (_tokensBound[_id]);
    }

    /**
     *  @dev See {ICompliance-addTokenAgent}.
     */
    function addTokenAgent(address _agentAddress) external override onlyOwner {
        require(!_tokenAgentsList[_agentAddress], 'This Agent is already registered');
        _tokenAgentsList[_agentAddress] = true;
        emit TokenAgentAdded(_agentAddress);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function removeTokenAgent(address _agentAddress) external override onlyOwner {
        require(_tokenAgentsList[_agentAddress], 'This Agent is not registered yet');
        _tokenAgentsList[_agentAddress] = false;
        emit TokenAgentRemoved(_agentAddress);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function bindToken(uint256 _id) external override onlyOwner {
        require(!_tokensBound[_id], 'This token is already bound');
        _tokensBound[_id] = true;
        emit TokenBound(_id);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function unbindToken(uint256 _id) external override onlyOwner {
        require(_tokensBound[_id], 'This token is not bound yet');
        _tokensBound[_id] = false;
        emit TokenUnbound(_id);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(
        address /* _from */,
        address /* _to */,
        uint256 /* _value */
    ) external view override returns (bool) {
        return true;
    }

    /**
     *  @dev See {ICompliance-transferred}.
     */
    function transferred(
        address /* _from */,
        address /* _to */,
        uint256 /* _value */
    ) external override {}

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address /* _to */, uint256 /* _value */) external override {}

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address /* _from */, uint256 /* _value */) external override {}

    /**
     *  @dev See {ICompliance-transferOwnershipOnComplianceContract}.
     */
    function transferOwnershipOnComplianceContract(address newOwner) external override onlyOwner {
        transferOwnership(newOwner);
    }
}