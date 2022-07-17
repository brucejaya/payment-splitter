contract ClaimRegistry {

    event ClaimRequested(
        uint256 indexed claimRequestId,
        uint256 indexed claimType,
        uint256 scheme,
        address indexed issuer,
        bytes32 signature,
        bytes32 data,
        string _uri
    );

    event ClaimAdded(
        bytes32 indexed claimId,
        uint256 indexed claimType,
        uint256 scheme,
        address indexed issuer,
        bytes32 signature,
        bytes32 data,
        string _uri
    );
   
    event ClaimRemoved(
        bytes32 indexed claimId,
        uint256 indexed claimType,
        uint256 scheme,
        address indexed issuer,
        bytes32 signature,
        bytes32 data,
        string _uri
    );

    event ClaimChanged(
        bytes32 indexed claimId,
        uint256 indexed claimType,
        uint256 scheme,
        address indexed issuer,
        bytes32 signature,
        bytes32 data,
        string _uri
    );

    struct Claim {
        uint256 claimType;
        uint256 scheme;
        bytes32 issuer; // msg.sender
        bytes32 signature; // this.address + claimType + data
        bytes32 data;
        string _uri;
    }

    mapping (bytes32 => Claim) claims;
    mapping (uint256 => bytes32[]) claimsByType;

    function addClaim(
        uint256 _claimType, 
        uint256 _scheme, 
        address _issuer, 
        bytes32 _signature, 
        bytes32 _data, 
        string memory _uri
    )
        public
        returns(bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(_issuer, _claimType));

        // if (msg.sender != address(this)) {
        //   require(keyHasPurpose(keccak256(msg.sender), 3), "Sender does not have claim signer key");
        // }

        if (claims[claimId].issuer != _issuer) {
            claimsByType[_claimType].push(claimId);
        }

        claims[claimId].claimType = _claimType;
        claims[claimId].scheme = _scheme;
        claims[claimId].issuer = _issuer;
        claims[claimId].signature = _signature;
        claims[claimId].data = _data;
        claims[claimId].uri = _uri;

        emit ClaimAdded(claimId, _claimType, _scheme, _issuer, _signature, _data, _uri );

        return claimId;
    }

    function removeClaim(
        bytes32 _claimId
    )
        public
        returns(bool success)
    {
        // if (msg.sender != address(this)) {
        //     require(keyHasPurpose(keccak256(msg.sender), 1), "Sender does not have management key");
        // }

        emit ClaimRemoved(_claimId, claims[_claimId].claimType, claims[_claimId].scheme, claims[_claimId].issuer, claims[_claimId].signature, claims[_claimId].data, claims[_claimId].uri );

        delete claims[_claimId];
        return true;
    }

    function getClaim(
        bytes32 _claimId
    )
        public
        returns(uint256 _claimType, uint256 _scheme, address _issuer, bytes32 _signature, bytes32 _data, string memory _uri)
    {
        return (claims[_claimId].claimType, claims[_claimId].scheme, claims[_claimId].issuer, claims[_claimId].signature, claims[_claimId].data, claims[_claimId].uri );
    }

    function getClaimIdsByType(
        uint256 _claimType
    )
        public
        returns(bytes32[] memory claimIds)
    {
        return claimsByType[_claimType];
    }

}
