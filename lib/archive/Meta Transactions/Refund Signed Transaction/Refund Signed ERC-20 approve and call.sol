

// execute call designed specifically for ERC-20 interactions
// from refund signed

contract ApproveNCall {

    /*//////////////////////////////////////////////////////////////
                            APPROVE AND CALL
    //////////////////////////////////////////////////////////////*/

    //  @dev include ethereum signed approve ERC20 and call hash 
    function approveAndCallSigned(
        address _baseToken, 
        address _to,
        uint256 _value,
        bytes _data,
        uint _nonce,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken,
        bytes _messageSignatures
    ) 
        external 
    {
        uint startGas = gasleft();
        // verify transaction parameters
        require(startGas >= _gasLimit);
        require(_nonce == nonce);
        require(_baseToken != address(0)); // _baseToken should be something!
        require(_to != address(this)); // no management with approveAndCall
        
        // calculates signHash
        bytes32 signHash = getSignHash(
            approveAndCallHash(
                _baseToken,
                _to,
                _value,
                keccak256(_data),
                _nonce,
                _gasPrice,
                _gasLimit,
                _gasToken               
            )
        );
        
        // verify if signatures are valid and came from correct actors;
        verifySignatures(
            ACTION, // no management with approveAndCall
            signHash, 
            _messageSignatures
        );
        
        approveAndCall(
            signHash,
            _baseToken,
            _to,
            _value,
            _data
        );

        // refund gas used using contract held ERC20 tokens or ETH
        if (_gasPrice > 0) {
            uint256 _amount = 21000 + (startGas - gasleft());
            _amount = _amount * _gasPrice;
            if (_gasToken == address(0)) {
                address(msg.sender).transfer(_amount);
            } else {
                ERC20Token(_gasToken).transfer(msg.sender, _amount);
            }
        }        
    }

    function approveAndCall(
        bytes32 _signHash,
        address _token,
        address _to,
        uint256 _value,
        bytes _data
    )
        private 
    {
        //executes transaction
        nonce++;
        ERC20Token(_token).approve(_to, _value);
        emit ExecutedGasRelayed(
            _signHash, 
            _to.call(_data)
        );
    }

    //  @dev get callHash
    function approveAndCallHash(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes32 _dataHash,
        uint _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken
    )
        public 
        view 
        returns (bytes32 approveCallHash) 
    {
        approveCallHash = keccak256(address(this),  APPROVEANDCALL_PREFIX,  _baseToken, _to, _value, _dataHash, _nonce, _gasPrice, _gasLimit, _gasToken);
    }
}
