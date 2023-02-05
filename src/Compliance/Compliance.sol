// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';

import '../../Interface/ICompliance.sol';
import '../../Interface/IToken.sol';
import '../../Interface/IAccounts.sol';

// TODO require(msg.sender == address(_token), "Only token contract can call this function");

contract ComplianceLimitHolder is ICompliance, Ownable  {

    ////////////////
    // CONTRACTS
    ////////////////

    // @dev the token on which this compliance contract is applied
    IToken public _token;

    // @dev the Identity registry contract linked to `token`
    IAccounts private _accounts;

    ////////////////
    // STATES
    ////////////////

    // @dev Mapping from token id to issuer
    mapping(uint256 => address) private _tokenIssuer;
    
    // @dev Mapping from token ID to the limit of holders for this token
    mapping(uint256 => uint256) private _holderLimit;

    // @dev Mapping from token ID to the index of each shareholder in the array `shareholders`
    mapping(uint256 => mapping(address => uint256)) private _holderIndices;

    // @dev Mapping from token ID to the amount of shareholders per country
    mapping(uint256 => mapping(uint16 => uint256)) private _countryShareHolders;

    // @dev Mapping from token ID to the addresses of all shareholders
    mapping(uint256 => address[]) private _shareholders;

    // @dev Mapping of tokens to if it is non-fractional or not 
    mapping(address => bool) private _nonFractional;

    // @dev Mapping of tokens to if it is non-fractional or not 
    mapping(address => uint256) private _tokenMinimum;

    // @dev Mapping from token ID to frozen accounts
    mapping(uint256 => mapping(address => bool)) internal _frozen;

    // @dev Mapping from token ID to freeze and pause functions
	mapping(uint256 => mapping(address => uint256)) internal _frozenTokens;
    
    // @dev Mapping from user address to freeze bool
    mapping(address => bool) internal _frozenAll;

    // @dev Mapping from token id to pause
    mapping(uint256 => bool) internal _tokenPaused;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address token
    ) {
        _token = IToken(token);
        _accounts = _token.identityRegistry();
    }

    event HolderLimitSet(uint256 _holderLimit, uint256 _id);

    ////////////////
    // MODIFIERS
    ////////////////
    
    modifier onlyTokenOrIssuer(
        uint256 id
    ) {
        require(msg.sender == address(_token) || _msgSender() == _tokenIssuer[id], "Only token contract can call this function");
        _;
    }

    modifier onlyIssuer(
        uint256 id
    ) {
        require(_msgSender() == _tokenIssuer[id], "Only token issuer can call this function");
        _;
    }

    modifier onlyToken(
        uint256 id
    ) {
        require(msg.sender == address(_token), "Only token contract can call this function");
        _;
    }
    
    modifier whenNotPaused(
        uint256 id
    ) {
        require(!_tokenPaused[id], "Pausable: paused");
        _;
    }

    modifier whenPaused(
        uint256 id
    ) {
        require(_tokenPaused[id], "Pausable: not paused");
        _;
    }

    ////////////////////////////////////////////////////////////////
    //                       READ FUNCTIONS
    ////////////////////////////////////////////////////////////////

    // #TODO replace these

    // @dev returns the holder limit as set for the token id 
    function getHolderLimit(
        uint256 id
    )
        external
        view
        returns (uint256) 
    {
        return _holderLimit[id];
    }

    // @dev returns the amount of token holders
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
        require(index < _shareholders[id].length, "shareholder doesn\"t exist");
        return _shareholders[id][index];
    }

    function paused(
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _tokenPaused[id];
    }

    function isFrozen(
        address account,
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _frozen[id][account];
    }

    function getFrozenTokens(
        address account,
        uint256 id     
    )
        public
        view
        returns (uint256)
    {
        return _frozenTokens[id][account];
    }

    // @notice Checks that modulus of the transfer amount is equal to one (with the standard eighteen decimal places) 
    function isNonFractional(
        address amount,
        uint256 id
    )
        public
        returns (bool)
    {
        if (amount % (1 * 10 ** 18) == 0) return true;  
        else return false;  
    }

    function isNotFrozen(
        address amount,
        uint256 id,
        address from,
        address to
    )
        public
        returns (bool)
    {
        if (!_frozen[id][to] && !_frozen[id][from]) return true;  
        else return false;  
    }

    function hasSufficientBalance(
        address amount,
        uint256 id,
        address from
    )
        public
        returns (bool)

    {
        if (amount <= _token.balanceOf(from, id) - (_frozenTokens[id][from])) return true;  
        else return false;  
    }
    
    function holderExists(
        uint256 id,
        address to
    )
        public
        returns (bool)

    {
        if (_holderIndices[id][to] != 0) return true;  
        else return false;  
    }
    
    function transferWithinLimit(
        uint256 id
    )
        public
        returns (bool)
    {
        if (holderCount(id) < _holderLimit[id]) return true;  
        else return false;  
    }

    ////////////////////////////////////////////////////////////////
    //                       FUNCTIONS
    ////////////////////////////////////////////////////////////////

    // @dev sets the holder limit as required for compliance purpose
    function setHolderLimit(
        uint256 holderLimit,
        uint256 id
    )
        external
        onlyIssuer
    {
        _holderLimit[id] = holderLimit;
        emit HolderLimitSet(holderLimit, id);
    }
    
    // TODO, enforce this
    function setMinimum(
        uint256 id,
        uint256 minimumAmount
    )
        external
        // TODO, make this safe...
    {
        _tokenMinimum[id] = minimumAmount;
        // emit UpdatedTokenInformation(_tokenIssuer);
    }

    function togglePause(
        uint256 id
    )
        external
        onlyIssuer 
    {
        if (!_tokenPaused[id]) {
            _tokenPaused[id] = true;
            emit Paused(_msgSender(), id);
        }
        else if (!_tokenPaused[id]) {
            _tokenPaused[id] = false;
            emit Unpaused(_msgSender(), id);
        }
    }
    
    function toggleNonFractional(
        uint256 id
    )
        external
        onlyIssuer 
    {
        if (!_nonFractional[id]) {
            _nonFractional[id] = true;
            emit Paused(_msgSender(), id);
        }
        else if (_nonFractional[id]) {
            _nonFractional[id] = false;
            emit Unpaused(_msgSender(), id);
        }
    }

    ////////////////////////////////////////////////////////////////
    //                       SHAREHOLDERS
    ////////////////////////////////////////////////////////////////
    
    function updateShareholders(
        address account,
        uint256 id
    )
        internal
    {
        if (_holderIndices[id][account] == 0) {
            _shareholders[id].push(account);
            _holderIndices[id][account] = _shareholders[id].length;
            uint16 country = _accounts.identityCountry(account);
            _countryShareHolders[id][country]++;
        }
    }

    function pruneShareholders(
        address account,
        uint256 id
    )
        internal
    {
        require(_holderIndices[id][account] != 0, "Shareholder does not exist");
        uint256 balance = _token.balanceOf(account, id);
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
        uint16 country = _accounts.identityCountry(account);
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

    ////////////////////////////////////////////////////////////////
    //                           FREEZE
    ////////////////////////////////////////////////////////////////

    function batchSetAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    )
        external
        onlyTokenOrIssuer
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            setAddressFrozen(accounts[i], ids[i], freeze[i]);
        }
    }

    function setAddressFrozen(
        address account,
        uint256 id,
        bool freeze
    )
        public
        onlyTokenOrIssuer 
    {
        _frozen[id][account] = freeze;
        emit AddressFrozen(account, freeze, _msgSender());
    }
    
    function batchFreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
    {
        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch");   
        for (uint256 i = 0; i < accounts.length; i++) {
            freezePartialTokens(accounts[i], ids[i], amounts[i]);
        }
    }

    function freezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyTokenOrIssuer
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        uint256 balance = _token.balanceOf(account, id);
        require(balance >= _frozenTokens[id][account] + amount, "Amount exceeds available balance");
        _frozenTokens[id][account] = _frozenTokens[id][account] + (amount);
        emit TokensFrozen(account, amount);
    }

    function batchUnfreezePartialTokens(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
    {
        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch");
        for (uint256 i = 0; i < accounts.length; i++) {
            unfreezePartialTokens(accounts[i], ids[i], amounts[i]);
        }
    }

    function unfreezePartialTokens(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyTokenOrIssuer 
    {        
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        require(_frozenTokens[id][account] >= amount, "Amount should be less than or equal to frozen tokens");
        _frozenTokens[id][account] = _frozenTokens[id][account] - (amount);
        // emit TokensUnfrozen(account, id, amount); TODO update event
    }

    ////////////////////////////////////////////////////////////////
    //                          TRANSFERS
    ////////////////////////////////////////////////////////////////

    function canTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    )
        external
        view
        returns (bool)
    {
        require(isNonFractional(amount, id), "Share transfers must be non-fractional");
        require(isNotFrozen(amount, id, from, to), "wallet is frozen");
        require(hasSufficientBalance(amount, id, from), "Insufficient Balance");
        require(holderExists(id, to), "Holder does not exist");
        require(transferWithinLimit(id), "Transfer exceeds holder limit"); 
        
        return true;
    }

    function updateFreeBalance(
        address from,
        uint256 id
    )
        public
    {
        uint256 freeBalance = _token.balanceOf(from, id) - (_frozenTokens[id][from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenTokens[id][from] = _frozenTokens[id][from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
    }

    function transferred(
        address from,
        address to,
        uint256 id
    )
        external
    {
        require(msg.sender == address(_token), "Only token contract can call this function");
        updateFreeBalance(from, id);
        updateShareholders(to, id);
        pruneShareholders(from, id);
    }

    function created(
        address to,
        uint256 id,
        uint256 amount
    )
        external
    {
        require(msg.sender == address(_token), "Only token contract can call this function");
        require(amount > 0, "No token created");
        updateShareholders(to, id);
    }

    function destroyed(
        address from,
        uint256 id
    )
        external
    {
        require(msg.sender == address(_token), "Only token contract can call this function");
        updateFreeBalance(from, id);
        pruneShareholders(from, id);
    }

}