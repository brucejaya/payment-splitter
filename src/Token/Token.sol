// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IAccounts.sol';
import '../../Interface/IClaimsRequired.sol';
import '../../Interface/ICompliance.sol';

import "openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Token is ERC1155 {
	
	// Contracts
    IAccounts public _accounts;
    ICompliance public _compliance;
    IClaimsRequired public _claimsRequired;

    // Constructor
    constructor(
		string memory uri,
        address claimsRequired,
        address compliance,
        address accounts
    )
        ERC1155(_uri)
    {
        _uri = uri;
		_accounts = accounts;
		_compliance = compliance;
		_claimsRequired = claimsRequired;
    }
        
	// Pre validate token transfer
	function preValidateTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public
        returns (bool)
    {
		address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);
        _beforeTokenTransfer(operator, from, to, ids, amounts, "");
		return true;
	}
	
	// Forced transferfrom
	function forcedTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
	)
		public
		virtual
		override 
		onlyOwner
	{
		_safeTransferFrom(from, to, id, amount, data);
	}

	// Forced batch transfer from
    function forcedBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		public
		virtual
		override 
		onlyOwner
	{
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

	// Recover tokens 
	function recover(
        address lostWallet,
        address newWallet,
        uint256 id,
        address account,
        bytes memory data
    )
        external
        onlyOwner 
        returns (bool)
    {
        require(balanceOf(lostWallet, id) != 0, "No tokens to recover");

        _accounts.registerAccount(newWallet, IAccounts(account), _accounts.accounts(lostWallet).country);
        _accounts.deleteAccount(lostWallet);

        forcedTransfer(lostWallet, newWallet, id, balanceOf(lostWallet, id), data);
		
        if (_compliance._frozenTokens[id][lostWallet] > 0) {
            _compliance.freezePartialTokens(newWallet, id, _compliance._frozenTokens[id][lostWallet]);
        }
        if (_compliance._frozen[id][lostWallet] == true) {
            _compliance.setAddressFrozen(newWallet, id, true);
        }
        emit RecoverySuccess(lostWallet, newWallet, account);

        return true;
    }

	// Setters
	function setAccounts(address accounts) public onlyOwner {
        _accounts = accounts;
    }

    function setCompliance(address compliance) public onlyOwner {
        _compliance = compliance;
    }

    function setClaimsRequired(address claimsRequired) public onlyOwner {
        _claimsRequired = claimsRequired;
    }

	// Before transfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		internal
		override
	{
        require(_claimsRequired.isVerified(to, id), "Accounts is not verified.");
        require(_compliance.canTransfer(to, from, id, amount), "Violates transfer limitations");
        require(_compliance.isNonFractional(amount, id), "Share transfers must be non-fractional");
	}

	// After transfer hook
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		internal
		override
	{
        _compliance.transferred(from, to, id);
	}

}