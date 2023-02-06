pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

import './IIdentityRegistry.sol';
import './IComplianceLimitHolder.sol';
import './IComplianceClaimsRequired.sol';

interface IEquity is IERC1155 {
    
    IAccounts public _accounts;
    ICompliance public _compliance;
    IClaimsRequired public _claimsRequired;

	function preValidateTransfer(address from, address to, uint256 id, uint256 amount ) external returns (bool);
	function forcedTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data ) external virtual override  onlyOwner;
    function forcedBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external virtual override  onlyOwner;
	function recover(address lostWallet, address newWallet, uint256 id, address account, bytes memory data ) external onlyOwner  returns (bool);
	function setAccounts(address accounts) external onlyOwner;
    function setCompliance(address compliance) external onlyOwner;
    function setClaimsRequired(address claimsRequired) external onlyOwner;
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) internal override;
    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) internal override;

}