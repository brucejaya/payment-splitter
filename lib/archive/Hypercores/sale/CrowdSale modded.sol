// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// TODO import '../../utils/ReentrancyGuard.sol';

import '../../Interface/ITokenRegistry.sol';
import '../../Interface/IHypercore.sol';

// @notice EquitySale contract that receives ETH or tokens to mint equity tokens.
contract EquitySale { // is ReentrancyGuard {
    
    event ExtensionSet(address issuer, uyyint256 listId, address purchaseToken, uint8 purchaseMultiplier, uint96 purchaseLimit, uint32 saleEnds);
    event ExtensionCalled(address indexed issuer, address indexed member, uint256 indexed amountOut);
    error NullMultiplier();
    error SaleEnded();
    error NotWhitelisted();
    error PurchaseLimit();
    
    ITokenRegistry public immutable tokenRegistry;

    mapping(address => EquitySale) public crowdsales;

    struct EquitySale {
        uint256 listId;
        address tokenRegistry;
        uint256 tokenId;
        address purchaseToken;
        uint8 purchaseMultiplier;
        uint96 purchaseLimit;
        uint96 amountPurchased;
        uint32 saleEnds;
    }

    // constructor(ITokenRegistry tokenRegistry_) {
    //     tokenRegistry = tokenRegistry_;
    // }

    function setExtension(
        bytes calldata extensionData
    )
        public
        nonReentrant
        virtual
    {
        (uint256 listId, address purchaseToken, uint8 purchaseMultiplier, uint96 purchaseLimit, uint32 saleEnds) = abi.decode(extensionData, (uint256, address, uint8, uint96, uint32));
        
        require(purchaseMultiplier != 0, "");

        crowdsales[msg.sender] = EquitySale({
            listId: listId,
            purchaseToken: purchaseToken,
            purchaseMultiplier: purchaseMultiplier,
            purchaseLimit: purchaseLimit,
            amountPurchased: 0,
            saleEnds: saleEnds
        });

        emit ExtensionSet(msg.sender, listId, purchaseToken, purchaseMultiplier, purchaseLimit, saleEnds);
    }

    function callExtension(
        address issuer,
        uint256 amount
    )
        public
        payable
        nonReentrant
        virtual
        returns (uint256 amountOut)
    {
        EquitySale storage sale = crowdsales[issuer];
        bytes memory extensionData = abi.encode(true);
        require(block.timestamp < sale.saleEnds, "Sale has already ended");
        if (sale.listId != 0) {
            
            // Require has claim is whitelisted by token issuer
            require(tokenRegistry.whitelistedAccounts(sale.listId, msg.sender), "");
        }
        if (sale.purchaseToken == address(0)) {
            amountOut = msg.value * sale.purchaseMultiplier;
            if (sale.amountPurchased + amountOut > sale.purchaseLimit) revert PurchaseLimit();
            issuer._safeTransferETH(msg.value); // send ETH to issuer
            sale.amountPurchased += uint96(amountOut);
            IHypercore(issuer).callExtension(msg.sender, amountOut, extensionData);
        }
        else {
            sale.purchaseToken._safeTransferFrom(msg.sender, issuer, amount); // send tokens to issuer
            amountOut = amount * sale.purchaseMultiplier;
            if (sale.amountPurchased + amountOut > sale.purchaseLimit) revert PurchaseLimit();
            sale.amountPurchased += uint96(amountOut);
            IHypercore(issuer).callExtension(msg.sender, amountOut, extensionData);
        }
        emit ExtensionCalled(msg.sender, issuer, amountOut);
    }
}
