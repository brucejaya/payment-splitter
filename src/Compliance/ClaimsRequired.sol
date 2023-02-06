// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IClaims.sol';
import '../../Interface/IClaimsRequired.sol';
import '../../Interface/IClaimVerifiers.sol';
import '../../Interface/IAccounts.sol';

contract ClaimsRequired is IClaimsRequired, Ownable {
    
  	////////////////
    // STATE
    ////////////////
    
    // @dev Claims contract
    IClaims public _claims;
    
    // @dev Claim verifiers 
    IClaimVerifiers public _claimVerifiers;
    
  	////////////////
    // STATE
    ////////////////

    // @dev Claims topics that will be required to hold shares
    mapping(uint256 => uint256[]) public _claimTopicsRequired;
    
    // @Dev Adresses that will be exempt
    mapping(address => bool) public _whitelisted;

  	////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address claims,
        address claimVerifiers
    ) {
        _claims = IClaims(claims);
        _claimVerifiers = IClaimVerifiers(claimVerifiers);

        emit claimsSet(claims);
        emit claimVerifiersSet(claimVerifiers);
    }

    //////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////    
    
    // @notice Add a claim topic to be required of holders
    function addClaimTopic(
        uint256 claimTopic,
        uint256 id
    )
        external
        onlyOwner
    {
        uint256 length = _claimTopicsRequired[id].length;
        for (uint256 i = 0; i < length; i++) {
            require(_claimTopicsRequired[id][i] != claimTopic, "Claim topic already exists");
        }
        _claimTopicsRequired[id].push(claimTopic);
        emit ClaimTopicAdded(claimTopic, id);
    }

    // @notice Remove claim topic required of holders
    function removeClaimTopic(
        uint256 claimTopic,
        uint256 id
    )
        external
        onlyOwner
    {
        uint256 length = _claimTopicsRequired[id].length;
        for (uint256 i = 0; i < length; i++) {
            if (_claimTopicsRequired[id][i] == claimTopic) {
                _claimTopicsRequired[id][i] = _claimTopicsRequired[id][length - 1];
                _claimTopicsRequired[id].pop();
                emit ClaimTopicRemoved(claimTopic, id);
                break;
            }
        }
    }

    // @notice Iterates through the claims comparing them to the Accounts to ensure the reciever has all of the appropriate claims
    function isVerified(
        address account,
        uint256 id
    )
        external
        view
        returns (bool)
    {
        if (address(account) == address(0)) {
            return false;
        }
        if (_claimTopicsRequired[id].length == 0) {
            return true;
        }
        if (_whitelisted[address] == true) {
            return true;
        }
        else {
            uint256 foundClaimTopic;
            uint256 scheme;
            address issuer;
            bytes memory sig;
            bytes memory data;
            uint256 claimTopic;
            for (claimTopic = 0; claimTopic < _claimTopicsRequired[id].length; claimTopic++) {
                bytes32[] memory claimIds = _claims.getClaimIdsByTopic(_claimTopicsRequired[id][claimTopic], account);
                if (claimIds.length == 0) {
                    return false;
                }
                for (uint256 j = 0; j < claimIds.length; j++) {
                    (foundClaimTopic, scheme, issuer, sig, data, ) = _claims.getClaim(claimIds[j], account);

                    try _claims.isClaimValid(
                        account,
                        _claimTopicsRequired[id][claimTopic],
                        sig,
                        data
                    )
                        returns(bool _validity)
                    {
                        if (
                            _validity
                            && _claimVerifiers.hasClaimTopic(issuer, _claimTopicsRequired[id][claimTopic])
                            && _claimVerifiers.isVerifier(issuer)
                        ) {
                            j = claimIds.length;
                        }
                        if (!_claimVerifiers.isVerifier(issuer) && j == (claimIds.length - 1)) {
                            return false;
                        }
                        if (!_claimVerifiers.hasClaimTopic(issuer, _claimTopicsRequired[id][claimTopic]) && j == (claimIds.length - 1)) {
                            return false;
                        }
                        if (!_validity && j == (claimIds.length - 1)) {
                            return false;
                        }
                    }
                    catch {
                        if (j == (claimIds.length - 1)) {
                            return false;
                        }
                    }
                }
            }
            return true;
        }
    }

    // @notice Add to whitelist
    function addToWhitelist(
        address account
    )
        external
        onlyOwner
    {
        _whitelisted[account] = true;
    }

    // @notice Remove from whitelist
    function removeFromWhitelist(
        address account
    )
        external
        onlyOwner
    {
        _whitelisted[account] = false;
    }

    // @notice Setters
    function setclaims(
        address claims
    )
        external
        onlyOwner
    {
        _claims = IClaims(claims);
        emit claimsSet(claims);
    }

    // @notice 
    function setClaimVerifiers(
        address claimVerifiers
    )
        external
        onlyOwner
    {
        _claimVerifiers = IClaimVerifiers(claimVerifiers);
        emit claimVerifiersSet(claimVerifiers);
    }
}