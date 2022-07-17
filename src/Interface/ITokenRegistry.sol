// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

import './IIdentityRegistry.sol';
import './IComplianceLimitHolder.sol';

interface ITokenRegistry is IERC1155 {

    event IdentityRegistryAdded(address indexed identityRegistry);

    event ComplianceAdded(address indexed compliance);

    event RecoverySuccess(address lostWallet, address newWallet, address holderIdentity);

    event AddressFrozen(address indexed account, bool indexed isFrozen, address indexed owner);

    event TokensFrozen(address indexed account, uint256 amount);

    event TokensUnfrozen(address indexed account, uint256 amount);

    event Paused(address account, uint256 id);

    event Unpaused(address account, uint256 id);

    function totalSupply(uint256 id) external view override returns (uint256);
    
    function Identity() external view override returns (address);

    function identityRegistry() external view override returns (IIdentityRegistry);

    function compliance() external view override returns (IComplianceLimitHolder);
  
    function paused(uint256 id) external view override returns (bool);
    
    function isFrozen(address account, uint256 id) external view override returns (bool);

    function getFrozenTokens(address account, uint256 id) external view override returns (uint256);
    
    function setURI(string memory uri) external;

    function setIdentity(address Identity) external override;

    function pause(uint256 id) external;

    function unpause(uint256 id) external;

    function setIdentityRegistry(address identityRegistry) external override;

    function setCompliance(address complianceAddress) external override;
    
    function transferOwnershipOnTokenContract(address newOwner) external;
    
    function addAgentOnTokenContract(address agent) external;

    function removeAgentOnTokenContract(address agent) external;

    function forcedTransfer(address from, address to, uint256 id, uint256 amount, bytes memory data) external returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function batchForcedTransfer(address[] memory fromList, address[] memory toList, uint256[] memory ids, uint256[] memory amounts, bytes[] memory dataList) external override;

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(address[] memory accounts, uint256 id, uint256[] memory amounts, bytes memory data) external;

    function setAddressFrozen(address account, uint256 id, bool freeze) external;

    function batchSetAddressFrozen(address[] memory accounts, uint256[] memory ids, bool[] memory freeze) external override;

    function freezePartialTokens(address account, uint256 id, uint256 amount) external;

    function batchFreezePartialTokens(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external override;

    function unfreezePartialTokens(address account, uint256 id, uint256 amount) external;

    function batchUnfreezePartialTokens(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external override;
    
    function burn(address from, uint256 id, uint256 amount) external;
    
    function burnBatch(address[] memory accounts, uint256 id, uint256[] memory amounts) external;

    function recoveryAddress(address lostWallet, address newWallet, uint256 id, address holderIdentity, bytes memory data) external override returns (bool);

}