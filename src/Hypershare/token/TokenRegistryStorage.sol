// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '../../Interface/ICompliance.sol';
import '../../Interface/IIdentityRegistry.sol';

contract TokenRegistryStorage {

    // @Dev Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // @Dev Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // @Dev Mapping from token ID to Wrapper contract address
    mapping(uint256 => address) internal _tokenWrapper;

    // @Dev Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
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

    // @dev Mapping from token id to pause
    mapping(uint256 => bool) internal _tokenPaused;

    // @dev Identity Registry contract used by the onchain validator system
    IIdentityRegistry internal _identityRegistry;

    // @dev Compliance contract linked to the onchain validator system
    ICompliance internal _compliance;
}