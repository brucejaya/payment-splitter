// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/ICompliance.sol';

contract DefaultCompliance is ICompliance, Ownable {
    /// @dev Mapping between agents and their statuses
    mapping(address => bool) private _tokenAgentsList;

    /// @dev Mapping of tokens linked to the compliance contract
    mapping(address => bool) private _tokensBound;

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function isTokenAgent(address _agentAddress) public view override returns (bool) {
        return (_tokenAgentsList[_agentAddress]);
    }

    /**
     *  @dev See {ICompliance-isTokenBound}.
     */
    function isTokenBound(address _token) public view override returns (bool) {
        return (_tokensBound[_token]);
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
    function bindToken(address _token) external override onlyOwner {
        require(!_tokensBound[_token], 'This token is already bound');
        _tokensBound[_token] = true;
        emit TokenBound(_token);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function unbindToken(address _token) external override onlyOwner {
        require(_tokensBound[_token], 'This token is not bound yet');
        _tokensBound[_token] = false;
        emit TokenUnbound(_token);
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
