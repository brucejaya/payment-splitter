// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// @Dev Hypercore extension interface.
interface IHypercore {
    function setExtension(bytes calldata extensionData) external;

    function callExtension(
        address account, 
        uint256 amount, 
        bytes calldata extensionData
    ) external payable returns (bool mint, uint256 amountOut);
}
