// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '../../Interface/IComplianceTokenRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';

contract TokenRegistryStorage {

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Mapping from token ID to Wrapper contract address
    mapping(uint256 => address) internal _tokenWrapper;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;

    // @dev Mapping from token ID to account balances
    mapping(uint256 => uint256) internal _totalSupply;

    // @dev Token information
    address internal _tokenIdentity;

    // @dev Mapping from token ID to frozen accounts
    mapping(uint256 => mapping(address => bool)) internal _frozen; // internal or internal?

    // @dev Mapping from token ID to freeze and pause functions
	mapping(uint256 => mapping(address => uint256)) internal _frozenTokens;
    
    // @dev Mapping from user address to freeze bool
    mapping(address => bool) internal _frozenAll;

    // 
    bool internal _tokenPaused = false;

    // @dev Identity Registry contract used by the onchain validator system
    IIdentityRegistry internal _tokenIdentityRegistry;

    // @dev Compliance contract linked to the onchain validator system
    IComplianceTokenRegistry internal _tokenCompliance;

    
    /**
     *  this event is emitted when the token information is updated.
     *  the event is emitted by the token constructor and by the setTokenInformation function
     *  `_newName` is the name of the token
     *  `_newSymbol` is the symbol of the token
     *  `_newDecimals` is the decimals of the token
     *  `_newVersion` is the version of the token, current version is 3.0
     *  `_newIdentity` is the address of the Identity of the token
     */
    // event UpdatedTokenInformation(string _newName, string _newSymbol, uint8 _newDecimals, string _newVersion, address _newIdentity);

    /**
     *  this event is emitted when the HolderRegistry has been set for the token
     *  the event is emitted by the token constructor and by the setHolderRegistry function
     *  `_holderRegistry` is the address of the Identity Registry of the token
     */
    event IdentityRegistryAdded(address indexed _holderRegistry);

    /**
     *  this event is emitted when the Compliance has been set for the token
     *  the event is emitted by the token constructor and by the setCompliance function
     *  `_compliance` is the address of the Compliance contract of the token
     */
    event ComplianceAdded(address indexed _compliance);

    /**
     *  this event is emitted when an investor successfully recovers his tokens
     *  the event is emitted by the recoveryAddress function
     *  `_lostWallet` is the address of the wallet that the investor lost access to
     *  `_newWallet` is the address of the wallet that the investor provided for the recovery
     *  `_investorIdentity` is the address of the Identity of the investor who asked for a recovery
     */
    event RecoverySuccess(address _lostWallet, address _newWallet, address _investorIdentity);

    /**
     *  this event is emitted when the wallet of an investor is frozen or unfrozen
     *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
     *  `_account` is the wallet of the investor that is concerned by the freezing status
     *  `_isFrozen` is the freezing status of the wallet
     *  if `_isFrozen` equals `true` the wallet is frozen after emission of the event
     *  if `_isFrozen` equals `false` the wallet is unfrozen after emission of the event
     *  `_owner` is the address of the agent who called the function to freeze the wallet
     */
    event AddressFrozen(address indexed _account, bool indexed _isFrozen, address indexed _owner);

    /**
     *  this event is emitted when a certain amount of tokens is frozen on a wallet
     *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
     *  `_account` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are frozen
     */
    event TokensFrozen(address indexed _account, uint256 _amount);

    /**
     *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
     *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
     *  `_account` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are unfrozen
     */
    event TokensUnfrozen(address indexed _account, uint256 _amount);

    /**
     *  this event is emitted when the token is paused
     *  the event is emitted by the pause function
     *  `_account` is the address of the wallet that called the pause function
     */
    event Paused(address _account);

    /**
     *  this event is emitted when the token is unpaused
     *  the event is emitted by the unpause function
     *  `_account` is the address of the wallet that called the unpause function
     */
    event Unpaused(address _account);

}
