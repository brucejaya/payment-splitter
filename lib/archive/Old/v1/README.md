Hypersurface
│
└───Interfaces
│   │   
│   └───IClaimVerifier.sol
│   └───IENSRegistry.sol
│   └───IENSResolver.sol
│   └───IERC20.sol
│   └───IERC725.sol
│   └───IERC735.sol
│   └───IERC1077.sol
│   └───IERC1271.sol
│   └───IERC3643.sol
│
└───Factory
│   │
│   └───HyperbaseFactory.sol
│   └───SubdomainFactory.sol
│   └───VentureFactory.sol
│
└───Registry
│   │
│   └───AuthenticatorRegistry.sol
│   └───CommitmentRegistry.sol
│
└───Hyperbase
│   │
│   └───Keys.sol
│   └───KeyRouter.sol
│   └───Claims.sol
│   └───ClaimRegistry.sol
│
└───Classes
│   │
│   └───Venture
│   │   │   
│   │   └───Equity   
│   │   │   │
│   │   │	└───EquityStorage.sol
│   │   │	└───EquityToken.sol
│   │   │	└───Keys.sol
│   │   │	└───Keys.sol
│   │   │
│   │   └───Sale
│   │   │   │
│   │   │	└───EquitySale.sol
│   │   │
│   │   └───Voting
│   │       │
│   │    	└─── ??
│   │
│   └───??
│   
└───??


Hypersurface
Hypersurface protocol seeks to provide a global digital equity infrastructure for venture investment.

	Interfaces
	Contract interfaces...

	Factory
	Contracts for deploying contracts on-chain. Used for non-standalone contract deployments...

	Registry
	The standalone contracts that register important information.

		IdentityRegistry.sol
		A registry of Hyperbase addresses that are recognised by the protocol.

		AuthenticatorRegistry.sol
		A registry of trusted claim issuers we have verified as authorised firms.

			Ideally, one day, this would be managed by regulators who sign digital attestation that a firm is is licensed and authorised.

	Hyperbase
	The account model for the Hypersurface protocol.

		Keys.sol
		The ERC-725 base key-value pair storage and proxy contract that is the at the nucleus of the Hyperbase model.

		KeyRouter.sol
		Key management. Receives and validates signatures allowing keys to sign transactions. 

		Claims.sol 
		Is the underlying ERC-735 claim storage for the Hyperbase account. 

		ClaimsHolder.sol
		For claim management. Allows users to sign claims on an account.

	Classes
	Purpose-built contract deployments.

		Ventures
		For startups seeking to raise venture funding. 

			Equity
			The contracts for tokenised equity.

				EquityStorage.sol
				The accounting logic for a tokenised equity. Storage is persistent meaning the token logic may be upgraded. 

				EquityToken.sol
				The token logic that governs the issue and transfer of tokenised equity. 
				
					The T-Rex is has been designed for a central claims registry and introduces a lot of seemingly convoluted and needless complex logic to support Tokenies other product OnChainID. Instead of a central claim registry, Hypersurface uses a claim holder that is associated with each account, somewhat like a personal ID card. The source code to is located in the `ClaimVerifer.sol` file and needs to be merged with token logic.

			Sale
			The contracts that govern the on-chain private equity sales.

				EquitySale.sol
				The crowd-sale contract for the sale and transfer of tokenised equity. Features novel startups specific sale logic. Namely, it records and returns historic price data for priced venture funding rounds.

			Voting
			The contracts the allow investors to vote on chain using their equity tokens.

				??