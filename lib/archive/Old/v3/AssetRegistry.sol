// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import './interfaces/IIdentityRegistry.sol';

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract AssetRegistry is ERC1155 {

    // @dev Identity Registry contract used by the validator system
    IIdentityRegistry internal identityRegistry;

    // TOKEN STORAGE

    // @dev Array of token IDs
    uint256[] tokenIDs;

    // @dev Mapping from token ID to account balances
    mapping(uint256 => uint256) private totalSupply;

    // @dev Mapping from token ID to issuer identity
    mapping(uint256 => bytes32) private issuerIdentity;

	// @dev Mapping from token ID to token paused
	mapping(uint256 => bool) private paused;

    // @dev Mapping from token ID to frozen accounts
    mapping(uint256 => mapping(address => bool)) internal frozen; // Private or internal?

    // @dev Mapping from token ID to freeze and pause functions
	mapping(uint256 => mapping(address => uint256)) internal frozenTokens;

    // COMPLIANCE CHECKS

    // @dev Mapping from token ID to the limit of holders for this token
    mapping(uint256 => uint256) private holderLimit;

    // @dev Mapping from token ID to the index of each shareholder in the array `shareholders`
    mapping(uint256 => mapping(address => uint256)) private holderIndices;

    // @dev Mapping from token ID to the amount of shareholders per country
    mapping(uint256 => mapping(uint16 => uint256)) private countryShareHolders;

    // @dev Mapping from token ID to the addresses of all shareholders
    mapping(uint256 => address[]) private shareholders;






    function initializeAsset(
        uint256 id,
        bytes32 identity // This should maybe be bytes32?
    )
        public
        // TODO, onlyManagement(_msgSender(), id)
    {

        // Get the token id
        tokenIDs.push(id);

        // Mapping from token ID to issuer identity
        issuerIdentity[id] = identity;

        // Mapping from token ID to token paused
        paused[id] = true;

    }

    function issueAsset(
        uint256 id,
        address to,
        uint256 amount,
        bytes memory data
    )
        public 
        // TODO, onlyManagement(_msgSender(), id)
    {
        _mint(to, id, amount, data);
        totalSupply[id] += amount;

    }

    function burnAsset(
        uint256 id,
        address to,
        uint256 amount,
        bytes memory data
    )
        public 
        // TODO, onlyManagement(_msgSender(), id)
    {
        _burn(to, id, amount);
        totalSupply[id] -= amount;
    }






    // @dev Checks if user is frozen
    function isFrozen(
        uint256 id, 
        address _userAddress
    )
        external view returns (bool)
    {
        return frozen[id][_userAddress];
    }

    // @dev 
    function getFrozenTokens(
        uint256 id,
        address _userAddress
    )
        external view returns (uint256)
    {
        return frozenTokens[id][_userAddress];
    }

    // @dev 
    function pause(
        uint256 id
    )
        external 
        // TODO, onlyManagement(_msgSender(), id)
    {
        paused[id] = true;
        // event
    }

    // @dev 
    function unpause(
        uint256 id
    )
        external
        // TODO, onlyManagement(_msgSender(), id)
    {
        paused[id] = false;
        // event
    }



    



    // @dev Prevalidate a token transfer, ensure that it is ellible
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
	)
        internal virtual override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Compliance pre validation checks
        for (uint256 i = 0; i < ids.length; ++i) {
            
            require(!frozen[ids[i]][to] && !frozen[ids[i]][msg.sender], 'wallet is frozen');
            require(amounts[i] <= balanceOf(msg.sender, ids[i]) - (frozenTokens[ids[i]][msg.sender]), 'Insufficient Balance');

			require(identityRegistry.isVerified(to), "Identity has not been verified");
            require(holderCount(ids[i]) < holderLimit[ids[i]], "Transfer will exceed maximum shareholders");
		}
		
    }

    // @dev Update token state to reflect transfer that has occurred
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
	)
        internal virtual override
    {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);

        // TODO Update the shiz bro
        for (uint256 i = 0; i < ids.length; ++i) {
            // Compliance updates
        }
    }

    // @dev sets the holder limit as required for compliance purpose 
    function setHolderLimit(
        uint256 id,
        uint256 _holderLimit
    )
        external 
        // TODO, management approvals required 
    {
        holderLimit[id] = _holderLimit;
        // event
    }
    
    // @dev returns the holder limit as set on the contract
    function getHolderLimit(
        uint256 id
    )
        external view returns (uint256)
    {
        return holderLimit[id];
    }

    // @dev returns the amount of token holders
    function holderCount(
        uint256 id
    )
        public view returns (uint256)
    {
        return shareholders[id].length;
    }

    
    // @dev By counting the number of token holders using `holderCount` you can retrieve the complete list of token holders, one at a time.
    function holderAt(
        uint256 id,
        uint256 index
    )
        external view returns (address)
    {
        require(index < shareholders[id].length, 'shareholder doesn\'t exist');
        return shareholders[id][index];
    }

    
    // @dev If the address is not in the `shareholders` array then push it and update the `holderIndices` mapping. 
    function updateShareholders(
        uint256 id,
        address addr
    )
        internal
    {
        if (holderIndices[id][addr] == 0) {
            shareholders[id].push(addr);
            holderIndices[id][addr] = shareholders[id].length;
            uint16 country = identityRegistry.investorCountry(addr);
            countryShareHolders[id][country]++;
        }
    }

    
    // @dev If the address is in the `shareholders` array and the forthcoming transfer or transferFrom will reduce their balance to 0, then we need to remove them from the shareholders array.
    function pruneShareholders(
        uint256 id, 
        address addr
    )
        internal
    {
        require(holderIndices[id][addr] != 0, 'Shareholder does not exist');
        uint256 balance = balanceOf(addr, id);
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[id][addr] - 1;
        uint256 lastIndex = shareholders[id].length - 1;
        address lastHolder = shareholders[id][lastIndex];
        shareholders[id][holderIndex] = lastHolder;
        holderIndices[id][lastHolder] = holderIndices[id][addr];
        shareholders[id].pop();
        holderIndices[id][addr] = 0;
        uint16 country = identityRegistry.investorCountry(addr);
        countryShareHolders[id][country]--;
    }


    // @dev get the amount of shareholders in a country index the index of the country, following ISO 3166-1
    function getShareholderCountByCountry(uint256 id, uint16 index) external view returns (uint256) {
        return countryShareHolders[id][index];
    }

    // @dev Returns true if the amount of holders post-transfer is less or equal to the maximum amount of token holders
    function canTransfer(
        uint256 id,
        address /* from */,
        address to,
        uint256 /* _value */
    )
        external view returns (bool)
    {
        if (holderIndices[id][to] != 0) {
            return true;
        }
        if (holderCount(id) < holderLimit[id]) {
            return true;
        }
        return false;
    }

    // @dev Updates the counter of shareholders if necessary
    function transferred(
        uint256 id,
        address from,
        address to,
        uint256 /*_value */
    )
        internal
    {
        updateShareholders(id, to);
        pruneShareholders(id, from);
    }

    // @dev Updates the counter of shareholders if necessary
    function created(
        uint256 id,
        address to,
        uint256 _value
    )
        internal
    {
        require(_value > 0, 'No token created');
        updateShareholders(id, to);
    }
    
    //  @dev Updates the counter of shareholders if necessary
    function destroyed(
        address _from, 
        uint256 /* _value */
    ) 
        internal
    {
        pruneShareholders(_from);
    }

    

}