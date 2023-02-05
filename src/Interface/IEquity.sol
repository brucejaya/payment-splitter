// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

import './IIdentityRegistry.sol';
import './IComplianceLimitHolder.sol';
import './IComplianceClaimsRequired.sol';

interface IToken is IERC1155 {
    
    event ComplianceLimitHolderAdded(address indexed complianceHolderLimit);
    event ComplianceClaimsRequiredAdded(address indexed complianceClaimsRequired);
    event IdentityRegistryAdded(address indexed identityRegistry);  
    
    function totalSupply(uint256 id) external view returns (uint256);
    function identityRegistry() external view returns (IIdentityRegistry);
    function complianceClaimsRequired() external view returns (IComplianceClaimsRequired);
    function complianceLimitHolder() external view returns (IComplianceLimitHolder);
    function paused(uint256 id) external view returns (bool);
    function isFrozen(address account, uint256 id) external view returns (bool);
    function getFrozenTokens(address account, uint256 id) external view returns (uint256);
    function uri(uint256) external view returns (string memory);
    function setURI(string memory uri) external;
    function pause(uint256 id) external;
    function unpause(uint256 id) external;
    function preValidateTransfer(address from, address to, uint256 id, uint256 amount) external;
    function forcedTransfer(address from, address to, uint256 id, uint256 amount, bytes memory data) external returns (bool);
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function batchForcedTransfer(address[] memory fromList, address[] memory toList, uint256[] memory ids, uint256[] memory amounts, bytes[] memory dataList) external;
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address[] memory accounts, uint256 id, uint256[] memory amounts, bytes memory data) external;
    function setAddressFrozen(address account, uint256 id, bool freeze) external;
    function batchSetAddressFrozen(address[] memory accounts, uint256[] memory ids, bool[] memory freeze) external;
    function freezePartialTokens(address account, uint256 id, uint256 amount) external;
    function batchFreezePartialTokens(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external;
    function unfreezePartialTokens(address account, uint256 id, uint256 amount) external;
    function batchUnfreezePartialTokens(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function burnBatch(address[] memory accounts, uint256 id, uint256[] memory amounts) external;
    function recover(address lostWallet, address newWallet, uint256 id, address holderIdentity, bytes memory data) external returns (bool);
    function setIdentityRegistry(address identityRegistry) external;
    function setComplianceClaimsRequired(address complianceClaimsRequired) external;
    function setComplianceLimitHolder(address complianceLimitHolder) external;
    function transferOwnershipOnTokenContract(address newOwner) external;
    
}