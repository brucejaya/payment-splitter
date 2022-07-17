// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import '..../Hyperbase/Claims.sol';
interface ClaimVerifier {

	event ClaimValid(ClaimHolder _identity, uint256 claimType);
	event ClaimInvalid(ClaimHolder _identity, uint256 claimType);

	function ClaimVerifier(address _trustedClaimHolder) public;
	function checkClaim(ClaimHolder _identity, uint256 claimType) public returns (bool claimValid);
	function claimIsValid(ClaimHolder _identity, uint256 claimType) public constant returns (bool claimValid);
	function getRecoveredAddress(bytes sig, bytes32 dataHash) public view returns (address addr);
}