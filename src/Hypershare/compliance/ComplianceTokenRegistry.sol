// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/IComplianceTokenRegistry.sol';
import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IHolderRegistry.sol';

contract ComplianceTokenRegistry is IComplianceTokenRegistry, Ownable  {

    // @dev the token on which this compliance contract is applied
    ITokenRegistry public _tokenRegistry;

    // @dev the Identity registry contract linked to `token`
    IHolderRegistry private _holderRegistry;
    
    // @dev Mapping between agents and their statuses
    mapping(address => bool) private _tokenAgentsList;

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

    /**
     * @dev Throws if called by any address that is not a token bound to the compliance.
     */
    modifier onlyToken() {
        require(isToken(), 'error : this address is not a token bound to the compliance contract');
        _;
    }

    /**
     *  @dev the constructor initiates the smart contract with the initial state variables
     *  @param tokenRegistry the address of the token registry contract
     */
    constructor(
        address tokenRegistry
    ) {
        _tokenRegistry = ITokenRegistry(tokenRegistry);
        _holderRegistry = _tokenRegistry.holderRegistry();
    }


    /**
     *  this event is emitted when the holder limit is set.
     *  the event is emitted by the setHolderLimit function and by the constructor
     *  `_holderLimit` is the holder limit for this token
     *  `_id` is the id of the token
     */
    event HolderLimitSet(uint256 _holderLimit, uint256 _id);


    /**
     *  @dev See {IComplianceTokenRegistry-isTokenAgent}.
     */
    function isTokenAgent(
        address agentAddress
    ) public view override returns (bool) {
        return (_tokenAgentsList[agentAddress]);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-isTokenBound}.
     */
    function isTokenBound(
        address id
    )
        public
        view
        override
        returns (bool)
    {
        return (_tokensBound[id]);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-addTokenAgent}.
     */
    function addTokenAgent(
        address agentAddress
    )
        external
        override
        onlyOwner
    {
        require(!_tokenAgentsList[agentAddress], 'This Agent is already registered');
        _tokenAgentsList[agentAddress] = true;
        emit TokenAgentAdded(agentAddress);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-isTokenAgent}.
     */
    function removeTokenAgent(
        address agentAddress
    )
        external
        override
        onlyOwner
    {
        require(_tokenAgentsList[agentAddress], 'This Agent is not registered yet');
        _tokenAgentsList[agentAddress] = false;
        emit TokenAgentRemoved(agentAddress);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-isTokenAgent}.
     */
    function bindToken(
        address id
    )
        external
        override
        onlyOwner
    {
        require(!_tokensBound[id], 'This token is already bound');
        _tokensBound[id] = true;
        emit TokenBound(id);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-isTokenAgent}.
     */
    function unbindToken(
        address id
    )
        external
        override
        onlyOwner
    {
        require(_tokensBound[id], 'This token is not bound yet');
        _tokensBound[id] = false;
        emit TokenUnbound(id);
    }

    /**
     *  @dev Returns true if the sender corresponds to a token that is bound with the Compliance contract
     */
    function isToken()
        internal
        view
        returns (bool)
    {
        return isTokenBound(msg.sender);
    }

    /**
     *  @dev sets the holder limit as required for compliance purpose
     *  @param holderLimit the holder limit for the token concerned
     *  This function can only be called by the agent of the Compliance contract
     *  emits a `HolderLimitSet` event
     */
    function setHolderLimit(
        uint256 id,
        uint256 holderLimit
    )
        external
        onlyOwner
    {
        _holderLimit[id] = holderLimit;
        emit HolderLimitSet(holderLimit);
    }

    /**
     *  @dev returns the holder limit as set for the token id 
     */
    function getHolderLimit(
        uint256 id
    )
        external
        view
        returns (uint256) 
    {
        return _holderLimit[id];
    }

    /**
     *  @dev returns the amount of token holders
     */
    function holderCount(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholders[id].length;
    }

    /**
     *  @dev By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return `address` the address of the token holder with the given index.
     */
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

    /**
     *  @dev If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param account The address to add as a shareholder if it's not already.
     */
    function updateShareholders(
        address account,
        uint256 id
    )
        internal
    {
        if (_holderIndices[id][account] == 0) {
            _shareholders[id].push(account);
            _holderIndices[id][account] = _shareholders[id].length;
            uint16 country = _holderRegistry.investorCountry(account);
            _countryShareHolders[id][country]++;
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param account The address to prune if their balance will be reduced to 0.
     *  @param id The token id.
     */
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
        uint16 country = _holderRegistry.investorCountry(account);
        _countryShareHolders[id][country]--;
    }

    /**
     *  @dev get the amount of shareholders in a country
     *  @param index the index of the country, following ISO 3166-1
     */
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

    /**
     *  @dev See {IComplianceTokenRegistry-canTransfer}.
     *  @return true if the amount of holders post-transfer is less or
     *  equal to the maximum amount of token holders
     */
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

    /**
     *  @dev See {IComplianceTokenRegistry-transferred}.
     *  updates the counter of shareholders if necessary
     */
    function transferred(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        external
        override
        onlyToken
    {
        updateShareholders(to, id);
        pruneShareholders(from, id);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-created}.
     *  updates the counter of shareholders if necessary
     */
    function created(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        external
        override
        onlyToken
    {
        require(amount > 0, 'No token created');
        updateShareholders(to, id);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-destroyed}.
     *  updates the counter of shareholders if necessary
     */
    function destroyed(
        address from,
        uint256 id,
        uint256 amount
    )
        external
        override
        onlyToken
    {
        pruneShareholders(from, id);
    }

    /**
     *  @dev See {IComplianceTokenRegistry-transferOwnershipOnComplianceContract}.
     */
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
