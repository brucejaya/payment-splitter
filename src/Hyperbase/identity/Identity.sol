// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-contracts/contracts/utils/Context.sol';

import '../../Interface/IIdentity.sol';

// marked as abstract as lacking execution logic from erc734
abstract contract Identity is Context, IIdentity, ERC1155Holder {
    
    ////////////////
    // KEYS
    ////////////////

    uint256 constant MANAGEMENT = 1;
    uint256 constant ACTION = 2;
    uint256 constant CLAIM = 3;
    uint256 constant ENCRYPTION = 4;
    
    mapping(uint256 => bytes32[]) internal _keysByPurpose;
    mapping(bytes32 => Key) internal _keys;

    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    ////////////////
    // CLAIMS
    ////////////////
    
    mapping(bytes32 => Claim) internal _claims;
    mapping(uint256 => bytes32[]) internal _claimsByTopic; 

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    ////////////////
    // EXECTIONS
    ////////////////

    mapping(uint256 => Transaction) internal _transactions;
    uint256 internal _transactionNonce;
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    ////////////////
    // INIT
    ////////////////

    function init(
        address initialManagementKey
    ) internal {
        bytes32 key = keccak256(abi.encode(initialManagementKey));
        _keys[key].key = key;
        _keys[key].purposes = [1];
        _keys[key].keyType = 1;
        _keysByPurpose[1].push(key);
        emit KeyAdded(key, 1, 1);
    }

    // function init(
    //     address[] accounts,
    //     address[] permissions
    // )
    //     internal
    // {
    //     uint256 managementCount;
    //     require (acccounts.lengths == permissions.length, "Accounts/permissions length mismatch");
    //     for (uint i=0; i < accounts.length; i++) {
    //         addOperator(accounts[i], permissions[i]);
    //         if (permissions[i] == MANAGEMENT) managementCount++;
    //     }
    //     revert(managementCount == 0, "Need at least one account manager");
    // }

    /*//////////////////////////////////////////////////////////////
                                 KEYS
    //////////////////////////////////////////////////////////////*/

    function addressToKey(
        address account
    )
        public 
        pure
        returns (bytes32 key)
    {
        return keccak256(abi.encode(account));
    }

    function getKey(
        bytes32 key
    )
        public
        override
        view
        returns(uint256[] memory purpose_, uint256 keyType_, bytes32 key_)
    {
        return (_keys[key].purposes, _keys[key].keyType, _keys[key].key);
    }

    function getKeyPurposes(
        bytes32 key
    )
        public
        override
        view
        returns(uint256[] memory purposes)
    {
        return (_keys[key].purposes);
    }

    function getKeysByPurpose(
        uint256 purpose
    )
        public
        override
        view
        returns(bytes32[] memory keys_)
    {
        return _keysByPurpose[purpose];
    }

    function addKey(
        bytes32 key,
        uint256 purpose,
        uint256 keyType
    )
        public
        override
        returns (bool success)
    {
        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender()), MANAGEMENT), "Permissions: Sender does not have management key");
        }
        if (_keys[key].key == key) {
            for (uint keyPurposeIndex = 0; keyPurposeIndex < _keys[key].purposes.length; keyPurposeIndex++) {
                uint256 purpose_ = _keys[key].purposes[keyPurposeIndex];
                if (purpose == purpose_) {
                    revert("Conflict: Key already has purpose");
                }
            }
            _keys[key].purposes.push(purpose);
        } else {
            _keys[key].key = key;
            _keys[key].purposes = [purpose];
            _keys[key].keyType = keyType;
        }

        _keysByPurpose[purpose].push(key);

        emit KeyAdded(key, purpose, keyType);

        return true;
    }

    function removeKey(
        bytes32 key,
        uint256 purpose
    )
        public
        override
        returns (bool success)
    {
        require(_keys[key].key == key, "NonExisting: Key isn't registered");

        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender()), MANAGEMENT), "Permissions: Sender does not have management key");
        }

        require(_keys[key].purposes.length > 0, "NonExisting: Key doesn't have such purpose");

        uint purposeIndex = 0;
        while (_keys[key].purposes[purposeIndex] != purpose) {
            purposeIndex++;

            if (purposeIndex >= _keys[key].purposes.length) {
                break;
            }
        }

        require(purposeIndex < _keys[key].purposes.length, "NonExisting: Key doesn't have such purpose");

        _keys[key].purposes[purposeIndex] = _keys[key].purposes[_keys[key].purposes.length - 1];
        _keys[key].purposes.pop();

        uint keyIndex = 0;

        while (_keysByPurpose[purpose][keyIndex] != key) {
            keyIndex++;
        }

        _keysByPurpose[purpose][keyIndex] = _keysByPurpose[purpose][_keysByPurpose[purpose].length - 1];
        _keysByPurpose[purpose].pop();

        uint keyType = _keys[key].keyType;

        if (_keys[key].purposes.length == 0) {
            delete _keys[key];
        }

        emit KeyRemoved(key, purpose, keyType);

        return true;
    }

    function keyHasPurpose(
        bytes32 key, 
        uint256 purpose
    )
        public
        override
        view
        returns(bool result)
    {
        if (_keys[key].key != 0) return false;

        for (uint keyPurposeIndex = 0; keyPurposeIndex < _keys[key].purposes.length; keyPurposeIndex++) {
            uint256 purpose_ = _keys[key].purposes[keyPurposeIndex];

            if (purpose == 1 || purpose == purpose_) return true;
        }

        return false;
    }

    /*//////////////////////////////////////////////////////////////
                                 CLAIMS
    //////////////////////////////////////////////////////////////*/

    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
        public
        override
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(issuer, topic));

        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender()), CLAIM), "Permissions: Sender does not have claim signer key");
        }

        if (_claims[claimId].issuer != issuer) {
            _claimsByTopic[topic].push(claimId);
            _claims[claimId].topic = topic;
            _claims[claimId].scheme = scheme;
            _claims[claimId].issuer = issuer;
            _claims[claimId].signature = signature;
            _claims[claimId].data = data;
            _claims[claimId].uri = uri;

            emit ClaimAdded(
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        } else {
            _claims[claimId].topic = topic;
            _claims[claimId].scheme = scheme;
            _claims[claimId].issuer = issuer;
            _claims[claimId].signature = signature;
            _claims[claimId].data = data;
            _claims[claimId].uri = uri;

            emit ClaimChanged(
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        }

        return claimId;
    }

    function removeClaim(
        bytes32 claimId
    )
        public
        override
        returns (bool success)
    {
        if (_msgSender() != address(this)) {
            require(keyHasPurpose(addressToKey(_msgSender()), CLAIM), "Permissions: Sender does not have CLAIM key");
        }

        if (_claims[claimId].topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        while (_claimsByTopic[_claims[claimId].topic][claimIndex] != claimId) {
            claimIndex++;
        }

        _claimsByTopic[_claims[claimId].topic][claimIndex] = _claimsByTopic[_claims[claimId].topic][_claimsByTopic[_claims[claimId].topic].length - 1];
        _claimsByTopic[_claims[claimId].topic].pop();

        emit ClaimRemoved(
            claimId,
            _claims[claimId].topic,
            _claims[claimId].scheme,
            _claims[claimId].issuer,
            _claims[claimId].signature,
            _claims[claimId].data,
            _claims[claimId].uri
        );

        delete _claims[claimId];

        return true;
    }

    function getClaim(
        bytes32 claimId
    )
        public
        override
        view
        returns (
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        return (
            _claims[claimId].topic,
            _claims[claimId].scheme,
            _claims[claimId].issuer,
            _claims[claimId].signature,
            _claims[claimId].data,
            _claims[claimId].uri
        );
    }

    function getClaimIdsByTopic(
        uint256 topic
    )
        public
        override
        view
        returns(bytes32[] memory claimIds)
    {
        return _claimsByTopic[topic];
    }

}