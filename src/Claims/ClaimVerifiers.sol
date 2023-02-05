// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../../Interface/IClaimVerifiers.sol';
import '../../Interface/IAccounts.sol';

contract ClaimVerifiers is IClaimVerifiers {
    
    // @dev Array containing all verifiers identity contract address.
    IAccounts[] public verifiers;

    // @dev Mapping between a trusted Verifier index and its corresponding claimsRequired.
    mapping(address => uint256[]) public verifierTrustedTopics;

    function getTrustedVerifiers()
        external
        view
        override
        returns (IAccounts[] memory)
    {
        // TODO
        return verifiers;
    }

    function isVerifier(
        address _Verifier
    )
        external
        view
        override
        returns (bool)
    {
        uint256 length = verifiers.length;
        for (uint256 i = 0; i < length; i++) {
            if (address(verifiers[i]) == _Verifier) {
                return true;
            }
        }
        return false;
    }

    function getTrustedVerifierClaimTopics(
        IAccounts _verifier
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        require(verifierTrustedTopics[address(_verifier)].length != 0, 'trusted Verifier doesn\'t exist');
        return verifierTrustedTopics[address(_verifier)];
    }

    function hasClaimTopic(
        address _Verifier,
        uint256 _claimTopic
    )
        external
        view
        override
        returns (bool)
    {
        uint256 length = verifierTrustedTopics[_Verifier].length;
        uint256[] memory claimsRequired = verifierTrustedTopics[_Verifier];
        for (uint256 i = 0; i < length; i++) {
            if (claimsRequired[i] == _claimTopic) {
                return true;
            }
        }
        return false;
    }

    function addTrustedVerifier(
        IAccounts _verifier,
        uint256[] calldata _claimsRequired
    )
        external
        override
        onlyOwner
    {
        require(verifierTrustedTopics[address(_verifier)].length == 0, 'trusted Verifier already exists');
        require(_claimsRequired.length > 0, 'trusted claim topics cannot be empty');
        verifiers.push(_verifier);
        verifierTrustedTopics[address(_verifier)] = _claimsRequired;
        emit TrustedVerifierAdded(_verifier, _claimsRequired);
    }

    function removeTrustedVerifier(
        IAccounts _verifier
    )
        external
        override
        onlyOwner
    {
        require(verifierTrustedTopics[address(_verifier)].length != 0, 'trusted Verifier doesn\'t exist');
        uint256 length = verifiers.length;
        for (uint256 i = 0; i < length; i++) {
            if (verifiers[i] == _verifier) {
                verifiers[i] = verifiers[length - 1];
                verifiers.pop();
                break;
            }
        }
        delete verifierTrustedTopics[address(_verifier)];
        emit TrustedVerifierRemoved(_verifier);
    }

    function updateVerifierClaimTopics(
        IAccounts _verifier,
        uint256[] calldata _claimsRequired
    )
        external
        override
        onlyOwner
    {
        require(verifierTrustedTopics[address(_verifier)].length != 0, 'trusted Verifier doesn\'t exist');
        require(_claimsRequired.length > 0, 'claim topics cannot be empty');
        verifierTrustedTopics[address(_verifier)] = _claimsRequired;
        emit ClaimTopicsUpdated(_verifier, _claimsRequired);
    }

}
