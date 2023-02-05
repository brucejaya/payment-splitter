// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IAccounts.sol';
import '../../Interface/IClaimsRequired.sol';
import '../../Interface/ICompliance.sol';

import "openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Token is ERC1155 {
	
	// Contracts
    IAccounts internal _accounts;
    ICompliance internal _compliance;
    IClaimsRequired internal _claimsRequired;

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
        require(from == _msgSender() || from == operator || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner, operator or approved");
        require(_claimsRequired.isVerified(to, id), "Identity is not verified.");
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