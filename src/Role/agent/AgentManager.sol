// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '../../Interface/IIdentity.sol';
import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';

import './AgentRoles.sol';

contract AgentManager is AgentRoles {
    
    /// @dev the tokenRegistry managed by this AgentManager contract
    ITokenRegistry public tokenRegistry;

    constructor(
        address _tokenRegistry
    ) {
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    function callForcedTransfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isTransferManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Transfer Manager'
        );
        tokenRegistry.forcedTransfer(_from, _to, _id, _amount, _data);
    }

    function callBatchForcedTransfer(
        address[] memory _fromList,
        address[] memory _toList,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes[] memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isTransferManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Transfer Manager'
        );
        tokenRegistry.batchForcedTransfer(_fromList, _toList, _ids, _amounts, _data);
    }

    function callPause(
        IIdentity _identity,
        uint256 _id
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.pause(_id);
    }

    function callUnpause(
        IIdentity _identity,
        uint256 _id
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.unpause(_id);
    }

    function callMint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.mint(_to, _id, _amount, _data);
    }

    function callMintBatch(
        address[] memory _accounts,
        uint256 _id,
        uint256[] memory _amounts,
        bytes memory _data,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.mintBatch(_accounts, _id, _amounts, _data);
    }

    function callBurn(
        address _account,
        uint256 _id,
        uint256 _amount,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.burn(_account, _id, _amount);
        
    }

    function callBurnBatch(
        address[] memory _accounts,
        uint256 _id,
        uint256[] memory _amounts,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.burnBatch(_accounts, _id, _amounts);
    }

    function callSetAddressFrozen(
        address _account,
        uint256 _id,
        bool _freeze,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.setAddressFrozen(_account, _id, _freeze);
    }

    function callBatchSetAddressFrozen(
        address[] calldata _accounts,
        uint256[] calldata _ids,
        bool[] calldata _freeze,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.batchSetAddressFrozen(_accounts, _ids, _freeze);
    }

    function callFreezePartialTokens(
        address _account,
        uint256 _id,
        uint256 _amount,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.freezePartialTokens(_account, _id, _amount);
    }

    function callBatchFreezePartialTokens(
        address[] calldata _accounts,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.batchFreezePartialTokens(_accounts, _ids, _amounts);
    }

    function callUnfreezePartialTokens(
        address _account,
        uint256 _ids,
        uint256 _amount,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.unfreezePartialTokens(_account, _ids, _amount);
    }

    function callBatchUnfreezePartialTokens(
        address[] calldata _accounts,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        IIdentity _identity
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.batchUnfreezePartialTokens(_accounts, _ids, _amounts);
    }

    function callRecoveryAddress(
        address _lostWallet,
        address _newWallet,
        uint256 _id,
        address _account,
        bytes memory _data,
        IIdentity _managerIdentity
    )
        external
    {
        require(
            isRecoveryAgent(address(_managerIdentity)) && _managerIdentity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Recovery Agent'
        );
        tokenRegistry.recoveryAddress(_lostWallet, _newWallet, _id, _account, _data);
    }

    function callRegisterIdentity(
        address _account,
        IIdentity _identity,
        uint16 _country,
        IIdentity _managerIdentity
    )
        external
    {
        require(
            isWhiteListManager(address(_managerIdentity)) && _managerIdentity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().registerIdentity(_account, _identity, _country);
    }

    function callUpdateIdentity(
        address _account,
        IIdentity _identity
    ) external {
        require(
            isWhiteListManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().updateIdentity(_account, _identity);
    }

    function callUpdateCountry(
        address _account,
        uint16 _country,
        IIdentity _identity
    ) external {
        require(
            isWhiteListManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().updateCountry(_account, _country);
    }

    function callDeleteIdentity(
        address _account,
        IIdentity _identity
    ) external {
        require(
            isWhiteListManager(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        tokenRegistry.identityRegistry().deleteIdentity(_account);
    }
}
