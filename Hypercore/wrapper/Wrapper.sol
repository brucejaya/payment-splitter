// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol';

import '../../Interface/ITokenRegistry.sol';

abstract contract Wrapper is ERC20, IERC1155Receiver {
    
    ITokenRegistry public _tokenRegistry;
    uint256 public _id;

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

    function wrapTokens(
        address account,
        uint256 amount
    ) public {
        // TODO require that token not paused...
        _mint(account, amount);
    }

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

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(_id == id, "Not acceptable");
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return "";
    }

}
