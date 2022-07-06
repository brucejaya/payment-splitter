// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol';
import '../../Interface/ITokenRegistry.sol';

// TODO, double check this should be marked abstract
contract Wrapper is ERC20, IERC1155Receiver {
    
    ITokenRegistry public token;
    uint256 public id;

    /**
     * @dev sets values for
     * @param _token address of token for which this wrapper is for
     * @param _id of the asset the contract is for
     * @param _name a descriptive name mentioning market and outcome
     * @param _symbol symbol
     * @param _decimals decimals
     */
    constructor(
        ITokenRegistry _token,
        uint256 _id,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol, _decimals) {
        id = _id;
        token = _token;
    }

    /**
     *  @dev Recieves ERC1155s and mints ERC20s
     * @param _account account the newly minted ERC20s will go to
     * @param _amount amount of tokens to be wrapped
     */
    function wrapTokens(
        address _account,
        uint256 _amount
    ) public {
        _mint(_account, _amount);
    }

    /**
     *  @dev A function that burns ERC20s and gives back ERC1155s
     *  - if the msg.sender is not hyperfoundry or _account then the caller must have allowance for ``_account``'s tokens of at least
     *  `amount`.
     *  - if the market has finalized then claim() function should be called.
     *  @param _account account the newly minted ERC20s will go to
     *  @param _amount amount of tokens to be unwrapped
     */
    function unWrapTokens(address _account, uint256 _amount) public {
        if (msg.sender != _account) {
            uint256 decreasedAllowance = allowance(_account, msg.sender).sub(
                _amount,
                "ERC20: burn amount exceeds allowance"
            );
            _approve(_account, msg.sender, decreasedAllowance);
        }

        // TODO, tripple check that no one can burn more than they have, or gets their assets burnt before the trasfer has been confired...
        
        _burn(_account, _amount);

        token.safeTransferFrom(address(this), _account, id, _amount, "" );
    }

    /**
     *  @dev Handles the receipt of a single ERC1155 token type. This function is
     *  called at the end of a `safeTransferFrom` after the balance has been updated.
     *  To accept the transfer, this must return
     *  `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *  (i.e. 0xf23a6e61, or its own function selector).
     *  @param _operator The address which initiated the transfer (i.e. msg.sender)
     *  @param _from The address which previously owned the token
     *  @param _id The ID of the token being transferred
     *  @param _value The amount of tokens being transferred
     *  @param _data Additional data with no specified format
     *  @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        /**@notice To make sure that no other id other than what this ERC20 is a wrapper for is sent here*/
        require(id == _id, "Not acceptable");
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
     *  @param _operator The address which initiated the batch transfer (i.e. msg.sender)
     *  @param _from The address which previously owned the token
     *  @param _ids An array containing ids of each token being transferred (order and length must match values array)
     *  @param _values An array containing amounts of each token being transferred (order and length must match ids array)
     *  @param _data Additional data with no specified format
     *  @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        /**@notice This is not allowed. Just transfer one predefined id here */
        return "";
    }

}
