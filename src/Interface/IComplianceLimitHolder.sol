// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// TODO UPDATE

interface IComplianceLimitHolder {
    
    event TokenAgentAdded(address agentAddress);

    event TokenAgentRemoved(address agentAddress);

    event TokenBound(address token);

    event TokenUnbound(address token);

    function isTokenAgent(address agentAddress) external view returns (bool);

    function isTokenBound(address token) external view returns (bool);

    function addTokenAgent(address agentAddress) external;

    function removeTokenAgent(address agentAddress) external;

    function bindToken(address token) external;

    function unbindToken(address token) external;

    function canTransfer(address to, uint256 id, uint256 amount, bytes memory data) external view override returns (bool);

    function transferred(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function created(address to, uint256 id, uint256 amount, bytes memory data) external;

    function destroyed(address from, uint256 id, uint256 amount) external;

    function transferOwnershipOnComplianceContract(address newOwner) external;
}
