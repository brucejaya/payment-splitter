// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol';

import '../../Interface/ITokenRegistry.sol';

abstract contract Wrapper is ERC20, IERC1155Receiver {
    
    ITokenRegistry public _tokenRegistry;
    uint256 public _id;

    /**
     * @dev sets values for
     * @param tokenRegistry address of tokenRegistry for which this wrapper is for
     * @param id of the asset the contract is for
     * @param name a descriptive name mentioning market and outcome
     * @param symbol symbol
     * @param decimals decimals
     */
    constructor(
        ITokenRegistry tokenRegistry,
        uint256 id,
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol)
    {
        _tokenRegistry = tokenRegistry;
        _id = id;
    }

    /**
     * @dev Recieves ERC1155s and mints ERC20s
     * @param account account the newly minted ERC20s will go to
     * @param amount amount of tokens to be wrapped
     */
    function wrapTokens(
        address account,
        uint256 amount
    ) public {
        _mint(account, amount);
    }

    /**
     *  @dev A function that burns ERC20s and gives back ERC1155s
     *  - if the msg.sender is not hyperfoundry or account then the caller must have allowance for ``account``'s tokens of at least
     *  `amount`.
     *  - if the market has finalized then claim() function should be called.
     *  @param account account the newly minted ERC20s will go to
     *  @param amount amount of tokens to be unwrapped
     */
    function unWrapTokens(
        address account, 
        uint256 amount
    )
        public
    {
        if (msg.sender != account) {
            uint _allowance =  allowance(account, msg.sender);
            require(_allowance > amount, "ERC20: burn amount exceeds allowance");
            uint256 decreasedAllowance =  _allowance - amount; 
            _approve(account, msg.sender, decreasedAllowance);
        }

        _burn(account, amount);

        _tokenRegistry.safeTransferFrom(address(this), account, _id, amount, "" );
    }

    /**
     *  @dev Handles the receipt of a single ERC1155 token type. This function is
     *  called at the end of a `safeTransferFrom` after the balance has been updated.
     *  To accept the transfer, this must return
     *  `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *  (i.e. 0xf23a6e61, or its own function selector).
     *  @param operator The address which initiated the transfer (i.e. msg.sender)
     *  @param from The address which previously owned the token
     *  @param id The ID of the token being transferred
     *  @param value The amount of tokens being transferred
     *  @param data Additional data with no specified format
     *  @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        /**@notice To make sure that no other id other than what this ERC20 is a wrapper for is sent here*/
        require(_id == id, "Not acceptable");
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    /**
     *  @dev Handles the receipt of a multiple ERC1155 token types. This function
     *  is called at the end of a `safeBatchTransferFrom` after the balances have
     *  been updated. To accept the transfer(s), this must return
     *  `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     *  (i.e. 0xbc197c81, or its own function selector).
     *  @param operator The address which initiated the batch transfer (i.e. msg.sender)
     *  @param from The address which previously owned the token
     *  @param ids An array containing ids of each token being transferred (order and length must match values array)
     *  @param values An array containing amounts of each token being transferred (order and length must match ids array)
     *  @param data Additional data with no specified format
     *  @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        /**@notice This is not allowed. Just transfer one predefined id here */
        return "";
    }

}
