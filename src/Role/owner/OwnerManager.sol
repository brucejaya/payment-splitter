// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';
import '../../Interface/IClaimVerifiersRegistry.sol';
import '../../Interface/IComplianceClaimsRequired.sol';
import '../../Interface/IComplianceLimitHolder.sol';
import '../../Interface/IIdentity.sol';
import '../../Interface/IClaimValidator.sol';
import './OwnerRoles.sol';

contract OwnerManager is OwnerRoles {

    ///  @dev the tokenRegistry that is managed by this OwnerManager Contract
    ITokenRegistry public tokenRegistry;

    event ComplianceInteraction(address indexed target, bytes4 selector);

    constructor(
        address _tokenRegistry
    ) {
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    function callSetIdentityRegistry(
        address _identityRegistry, 
        IIdentity _identity
    )
        external
    {
        require(
            isRegistryAddressSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        tokenRegistry.setIdentityRegistry(_identityRegistry);
    }

    function callSetCompliance(
        address _compliance,
        IIdentity _identity
    )
       external
    {
        require(
            isComplianceSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Compliance Setter'
        );
        tokenRegistry.setCompliance(_compliance);
    }

    function callComplianceFunction(
        bytes calldata callData, 
        IIdentity _identity
    )
        external
    {
        require(
            isComplianceManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Compliance Manager');
            address target = address(tokenRegistry.compliance()
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            calldatacopy(freeMemoryPointer, callData.offset, callData.length)
            if iszero(
                call(
                    gas(),
                    target,
                    0,
                    freeMemoryPointer,
                    callData.length,
                    0,
                    0
                    ))
                {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

        emit ComplianceInteraction(target, selector(callData));

        }

    /// @dev Extracts the Solidity ABI selector for the specified interaction.
    function selector(
        bytes calldata callData
    )
        internal
        pure
        returns (bytes4 result) 
    {
        if (callData.length >= 4) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                result := calldataload(callData.offset)
            }
        }
    }


    function callSetTokenOnchainID(
        address _tokenRegistryOnchainID,
        IIdentity _identity
    )
        external
    {
        require(
            isTokenInfoManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        tokenRegistry.setIdentity(_tokenRegistryOnchainID);
    }

    function callSetComplianceClaimsRequired(
        address _ComplianceClaimsRequired,
        IIdentity _identity
    )
        external
    {
        require(
            isRegistryAddressSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        tokenRegistry.identityRegistry().setComplianceClaimsRequired(_ComplianceClaimsRequired);
    }

    function callSetTrustedVerifierssRegistry(
        address _trustedVerifiersRegistry,
        IIdentity _identity
    )
        external
    {
        require(
            isRegistryAddressSetter(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        tokenRegistry.identityRegistry().setClaimVerifiersRegistry(_trustedVerifiersRegistry);
    }

    function callAddTrustedVerifiers(
        IClaimValidator _trustedVerifier,
        uint256[] calldata _claimTopics,
        IIdentity _identity
    )
        external
    {
        require(
            isVerifiersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT VerifiersRegistryManager'
        );
        tokenRegistry.identityRegistry().claimVerifiersRegistry().addTrustedVerifier(_trustedVerifier, _claimTopics);
    }

    function callRemoveTrustedVerifiers(
        IClaimValidator _trustedVerifier, 
        IIdentity _identity
    )
        external
    {
        require(
            isVerifiersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT VerifiersRegistryManager'
        );
        tokenRegistry.identityRegistry().claimVerifiersRegistry().removeTrustedVerifier(_trustedVerifier);
    }

    function callUpdateVerifierClaimTopics(
        IClaimValidator _trustedVerifier,
        uint256[] calldata _claimTopics,
        IIdentity _identity
    )
        external
    {
        require(
            isVerifiersRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT VerifiersRegistryManager'
        );
        tokenRegistry.identityRegistry().claimVerifiersRegistry().updateVerifierClaimTopics(_trustedVerifier, _claimTopics);
    }

    function callAddClaimTopic(
        uint256 _claimTopic, 
        IIdentity _identity
    )
        external
    {
        require(
            isClaimRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT ClaimRegistryManager'
        );
        tokenRegistry.identityRegistry().complianceClaimsRequired().addClaimTopic(_claimTopic);
    }

    function callRemoveClaimTopic(
        uint256 _claimTopic, 
        IIdentity _identity
    )
        external
    {
        require(
            isClaimRegistryManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT ClaimRegistryManager'
        );
        tokenRegistry.identityRegistry().complianceClaimsRequired().removeClaimTopic(_claimTopic);
    }

    function callTransferOwnershipOnTokenContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.transferOwnershipOnTokenContract(_newOwner);
    }

    function callTransferOwnershipOnIdentityRegistryContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().transferOwnershipOnIdentityRegistryContract(_newOwner);
    }

    function callTransferOwnershipOnComplianceContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.compliance().transferOwnershipOnComplianceContract(_newOwner);
    }

    function callTransferOwnershipOnComplianceClaimsRequiredContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().complianceClaimsRequired().transferOwnershipOnComplianceClaimsRequiredContract(_newOwner);
    }

    function callTransferOwnershipOnVerifiersRegistryContract(
        address _newOwner
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().claimVerifiersRegistry().transferOwnershipOnVerifiersRegistryContract(_newOwner);
    }

    function callAddAgentOnTokenContract(
        address _agent
    ) 
        external 
        onlyAdmin 
    {
        tokenRegistry.addAgentOnTokenContract(_agent);
    }

    function callRemoveAgentOnTokenContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.removeAgentOnTokenContract(_agent);
    }

    function callAddAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().addAgentOnIdentityRegistryContract(_agent);
    }

    function callRemoveAgentOnIdentityRegistryContract(
        address _agent
    )
        external
        onlyAdmin
    {
        tokenRegistry.identityRegistry().removeAgentOnIdentityRegistryContract(_agent);
    }
}