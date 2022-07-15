// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/ICompliance.sol';
import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IIdentityRegistry.sol';

contract Compliance is ICompliance, Ownable  {

    // @dev the token on which this compliance contract is applied
    ITokenRegistry public _tokenRegistry;

    // @dev the Identity registry contract linked to `token`
    IIdentityRegistry private _identityRegistry;
    
    // @dev Mapping from token id to agents and their statuses
    mapping(uint256 => mapping(address => bool)) private _tokenAgentsList;

    // @dev Mapping of tokens linked to the compliance contract
    mapping(address => bool) private _tokensBound;
    
    //  @dev Mapping from token ID to the limit of holders for this token
    mapping(uint256 => uint256) private _holderLimit;

    //  @dev Mapping from token ID to the index of each shareholder in the array `shareholders`
    mapping(uint256 => mapping(address => uint256)) private _holderIndices;

    //  @dev Mapping from token ID to the amount of shareholders per country
    mapping(uint256 => mapping(uint16 => uint256)) private _countryShareHolders;

    //  @dev Mapping from token ID to the addresses of all shareholders
    mapping(uint256 => address[]) private _shareholders;

    //  @dev the constructor initiates the smart contract with the initial state variables
    constructor(
        address tokenRegistry
    ) {
        _tokenRegistry = ITokenRegistry(tokenRegistry);
        _identityRegistry = _tokenRegistry.identityRegistry();
    }

    event HolderLimitSet(uint256 _holderLimit, uint256 _id);

    function isTokenAgent(
        address agentAddress,
        uint256 id
    ) public view override returns (bool) {
        return (_tokenAgentsList[id][agentAddress]);
    }

    function addTokenAgent(
        address agentAddress,
        uint256 id
    )
        external
        override
        onlyOwner
    {
        require(!_tokenAgentsList[id][agentAddress], 'This Agent is already registered');
        _tokenAgentsList[id][agentAddress] = true;
        emit TokenAgentAdded(agentAddress);
    }

    function removeTokenAgent(
        address agentAddress,
        uint256 id
    )
        external
        override
        onlyOwner
    {
        require(_tokenAgentsList[id][agentAddress], 'This Agent is not registered yet');
        _tokenAgentsList[id][agentAddress] = false;
        emit TokenAgentRemoved(agentAddress);
    }

    //  @dev sets the holder limit as required for compliance purpose
    function setHolderLimit(
        uint256 holderLimit,
        uint256 id
    )
        external
        onlyOwner
    {
        _holderLimit[id] = holderLimit;
        emit HolderLimitSet(holderLimit, id);
    }

    //  @dev returns the holder limit as set for the token id 
    function getHolderLimit(
        uint256 id
    )
        external
        view
        returns (uint256) 
    {
        return _holderLimit[id];
    }

    //  @dev returns the amount of token holders
    function holderCount(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholders[id].length;
    }

    function holderAt(
        uint256 index,
        uint256 id
    )
        external
        view
        returns (address)
    {
        require(index < _shareholders[id].length, 'shareholder doesn\'t exist');
        return _shareholders[id][index];
    }

    function updateShareholders(
        address account,
        uint256 id
    )
        internal
    {
        if (_holderIndices[id][account] == 0) {
            _shareholders[id].push(account);
            _holderIndices[id][account] = _shareholders[id].length;
            uint16 country = _identityRegistry.holderCountry(account);
            _countryShareHolders[id][country]++;
        }
    }

    function pruneShareholders(
        address account,
        uint256 id
    )
        internal
    {
        require(_holderIndices[id][account] != 0, 'Shareholder does not exist');
        uint256 balance = _tokenRegistry.balanceOf(account, id);
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = _holderIndices[id][account] - 1;
        uint256 lastIndex = _shareholders[id].length - 1;
        address lastHolder = _shareholders[id][lastIndex];
        _shareholders[id][holderIndex] = lastHolder;
        _holderIndices[id][lastHolder] = _holderIndices[id][account];
        _shareholders[id].pop();
        _holderIndices[id][account] = 0;
        uint16 country = _identityRegistry.holderCountry(account);
        _countryShareHolders[id][country]--;
    }

    function getShareholderCountByCountry(
        uint16 index,
        uint256 id
    )
        external
        view
        returns (uint256)
    {
        return _countryShareHolders[id][index];
    }

    function canTransfer(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        external
        view
        override
        returns (bool)
    {
        if (_holderIndices[id][to] != 0) {
            return true;
        }
        if (holderCount(id) < _holderLimit[id]) {
            return true;
        }
        return false;
    }

    function transferred(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        external
        override
    {
        require(msg.sender == address(_tokenRegistry), "Only token contract can call this function");
        updateShareholders(to, id);
        pruneShareholders(from, id);
    }

    function created(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        external
        override
    {
        require(msg.sender == address(_tokenRegistry), "Only token contract can call this function");
        require(amount > 0, 'No token created');
        updateShareholders(to, id);
    }

    function destroyed(
        address from,
        uint256 id,
        uint256 amount
    )
        external
        override
    {
        require(msg.sender == address(_tokenRegistry), "Only token contract can call this function");
        pruneShareholders(from, id);
    }

    function transferOwnershipOnComplianceContract(
        address _newOwner
    )
        external
        override
        onlyOwner
    {
        transferOwnership(_newOwner);
    }
}
