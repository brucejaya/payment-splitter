// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IAccounts.sol';
import '../../Interface/IClaimsRequired.sol';
import '../../Interface/ICompliance.sol';

import "openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

contract Equity is ERC1155, ERC1155Pausable {
	
    ////////////////
    // STATES
    ////////////////

    // @notice
    IAccounts public _accounts;

    // @notice
    ICompliance public _compliance;

    // @notice
    IClaimsRequired public _claimsRequired;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
		string memory uri_,
        address claimsRequired,
        address compliance,
        address accounts
    )
        // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
        ERC1155(uri_)
    {
		_accounts = accounts;
		_compliance = compliance;
		_claimsRequired = claimsRequired;
    }

    //////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////

	// @notice Pre validate token transfer
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
	
	// @notice Forced transferfrom
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

	// @notice Forced batch transfer from
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

	// @notice Recover tokens 
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
        // Sanity checks
        require(balanceOf(lostWallet, id) != 0, "No tokens to recover");

        // Create new account, delete old account
        _accounts.registerAccount(account, _accounts.accounts(lostWallet).country);

        // Delete account
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

	// @notice Setters
	function setAccounts(
        address accounts
    )
        public
        onlyOwner
    {
        _accounts = accounts;
    }

    // @notice
    function setCompliance(
        address compliance
    )
        public
        onlyOwner 
    {
        _compliance = compliance;
    }

    // @notice
    function setClaimsRequired(
        address claimsRequired
    ) 
        public 
        onlyOwner
    {
        _claimsRequired = claimsRequired;
    }

	// @notice Before transfer hook
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
	}

	// @notice After transfer hook
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