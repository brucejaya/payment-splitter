// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract IdentityExtender {
	
    ////////////////
    // EXTENSIONS
    ////////////////

    mapping(address => bool) public extentions;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    function init(
        address[] memory extentions_,
        bytes[] memory extentionsData_
    )
        public
        payable
        nonReentrant
        virtual
    {
        require(extentions_.length == extentionsData_.length, "Lengths do not match");
        if (extentions_.length != 0) {
            unchecked { // cannot realistically overflow on human timescales
                for (uint256 i; i < extentions_.length; i++) {
                    extentions[extentions_[i]] = true;

                    if (extentionsData_[i].length != 0) {
                        (bool success, ) = extentions_[i].call(extentionsData_[i]);
                        require(success, "Error adding extensions");
                    }
                }
            }
        }
    }


    ////////////////////////////////////////////////////////////////
    //                         HYPERCORES 
    ////////////////////////////////////////////////////////////////
    
    function init(
        address[] memory extentions_,
        bytes[] memory extentionsData_
    )
        public
        payable
        nonReentrant
        virtual
    {
        require(extentions_.length == extentionsData_.length, "Lengths do not match");
        if (extentions_.length != 0) {
            unchecked { // cannot realistically overflow on human timescales
                for (uint256 i; i < extentions_.length; i++) {
                    extentions[extentions_[i]] = true;

                    if (extentionsData_[i].length != 0) {
                        (bool success, ) = extentions_[i].call(extentionsData_[i]);
                        require(success, "Error adding extensions");
                    }
                }
            }
        }
    }

    function addExetension(
        address memory extentions_,
        bytes memory extentionsData_
    )
        public
    {
        extentions[extentions_[i]] = true;
        (bool success, ) = extentions_.call(extentionsData_);
        require(success, "Error adding extensions");
    }
    
    function callExtension(
        address extension, 
        uint256 amount,     
        bytes calldata extensionData
    )
        public
        payable
        nonReentrant
        virtual
        returns (bool mint, uint256 amountOut)
    {

        require(extentions[extension] && extentions[msg.sender], "Extension does not exist");
        
        address account;

        if (extentions[msg.sender]) {
            account = extension;
            amountOut = amount;
            mint = abi.decode(extensionData, (bool));
        }
        else {
            account = msg.sender;
            (mint, amountOut) = IHypercore(extension).callExtension{value: msg.value}(msg.sender, amount, extensionData);
        }
        
        if (mint) {
            if (amountOut != 0) {
                _mint(account, amountOut); 
            }
        }
        else {
            if (amountOut != 0) {
                _burn(account, amount);
            }
        }
    }

}