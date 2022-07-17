How does a proxy contract work?

Okay so the KeyHolder.sol is the original and came with the ERC-725 and ERC-735 implementation
KeyRouter.sol on the other hand, is the implementation that came with the ERC-1077 implementation.
KeyRouter seems to feature custom logic that is specific to specific to the relay

So what needs to be figured out?

	How does KeyHolder work?
	How does KeyRouter differ?
	How does KeyRelay work?
	How can KeyRelay be turned into a manageable multi-signature authenticator?

		@https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1077.md
		More than one signed transaction with the same parameter can be executed by this function at the same time, by passing all signatures in the messageSignatures field. That field will split the signature in multiple 72 character individual signatures and evaluate each one. This is used for cases in which one action might require the approval of multiple parties, in a single transaction.

	
	# And, ensure that KeyRelay is backwards compatible with a standard wallet? 
		It should be? Normal wallets can just sign stuff


ERC-191		-> 
ERC-712		-> 	Human readable signed data
ERC-1077	-> 	Executable signed messages
ERC-1271	-> 	Contract signed data
					https://eips.ethereum.org/EIPS/eip-1271


Use 1271 to authenticate transactions from Hyperbook?

	Smart contract Wallets use ERC-1271, so should Hypersurface

	Can also use ERC-1271 in governance?

	Externally Owned Accounts (EOA) can sign messages with their associated private keys, but currently contracts cannot. We propose a standard way for any contracts to verify whether a signature on a behalf of a given contract is valid. This is possible via the implementation of a isValidSignature(hash, signature) function on the signing contract, which can be called to validate a signature.

	There are and will be many contracts that want to utilize signed messages for validation of rights-to-move assets or other purposes. In order for these contracts to be able to support non Externally Owned Accounts (i.e., contract owners), we need a standard mechanism by which a contract can indicate whether a given signature is valid or not on its behalf.

	isValidSignature can call arbitrary methods to validate a given signature, which could be context dependent (e.g. time based or state based), EOA dependent (e.g. signers authorization level within smart wallet), signature scheme Dependent (e.g. ECDSA, multisig, BLS), etc.