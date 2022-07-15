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

    /**
     *  @dev calls the `forcedTransfer` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-forcedTransfer}.
     *  Requires that `_identity` is set as TransferManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `batchForcedTransfer` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-batchForcedTransfer}.
     *  Requires that `_identity` is set as TransferManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `pause` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-pause}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callPause(
        IIdentity _identity,
        uint256 _id
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.pause(_id);
    }

    /**
     *  @dev calls the `unpause` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-unpause}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callUnpause(
        IIdentity _identity,
        uint256 _id
    )
        external
    {
        require(isFreezer(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        tokenRegistry.unpause(_id);
    }

    /**
     *  @dev calls the `mint` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-mint}.
     *  Requires that `_identity` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `mintBatch` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-mintBatch}.
     *  Requires that `_identity` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `burn` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-burn}.
     *  Requires that `_identity` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `burnBatch` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-burnBatch}.
     *  Requires that `_identity` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBurnBatch(
        address[] calldata _accounts,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        IIdentity _identity
    )
        external
    {
        require(
            isSupplyModifier(address(_identity)) && _identity.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        tokenRegistry.burnBatch(_accounts, _ids, _amounts);
    }

    /**
     *  @dev calls the `setAddressFrozen` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-setAddressFrozen}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `batchSetAddressFrozen` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-batchSetAddressFrozen}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `freezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-freezePartialTokens}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `batchFreezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-batchFreezePartialTokens}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `unfreezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-unfreezePartialTokens}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `batchUnfreezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-batchUnfreezePartialTokens}.
     *  Requires that `_identity` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `recoveryAddress` function on the Token contract
     *  AgentManager has to be set as agent on the tokenRegistry smart contract to process this function
     *  See {ITokenRegistry-recoveryAddress}.
     *  Requires that `_managerIdentity` is set as RecoveryAgent on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_managerIdentity`
     *  @param _managerIdentity the onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `registerIdentity` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-registerIdentity}.
     *  Requires that `ManagerOnchainID` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_managerIdentity`
     *  @param _managerIdentity the onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `updateIdentity` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-updateIdentity}.
     *  Requires that `_identity` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `updateCountry` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-updateCountry}.
     *  Requires that `_identity` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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

    /**
     *  @dev calls the `deleteIdentity` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-deleteIdentity}.
     *  Requires that `_identity` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_identity`
     *  @param _identity the _identity contract of the caller, e.g. "i call this function and i am Bob"
     */
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
