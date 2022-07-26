# Hypersurface Protocol

**Welcome to Hypersurface: a digital equity infrastructure for the internet age.**

Hypersurface reconfigures many of the control structures that businesses operate on using non-legal, code-based mechanisms. The protocol enables lightweight, accessible and open digital equity on the blockchain. The aim of which is to provide a complete suite of tools, allowing issuers and holders to engage with tokenised equity assets easily, effectively, and securely. 

## To-do
The core protocol is (remarkably) approaching complete MVP. It is not tidy. The protocol needs to go through the wash many, many times. However, the fundamental structure and core components are mostly present. Next steps are: 

1. Consider the relative strengths of an ERC-745 claims holder as compared to an ERC-780 claims registry
2. Bool based approvals in `identity/MultiSignature.sol` and identity is complete...
3. Same controls applied recursively to form organisation accounts?
4. Refactor Kali code base with support for Hypercores, particular focus on modularity and extensibility
5. Subdomains!
6. Factory, storage, upgradeability 
7. Access controls everywhere
8. Events everywhere

## Protocol Architecture

The Hypersurface Protocol primarily consists of two core components, each with several sub-components split into folders. The following section will provide a brief overview of each of the core technical components within the protocol, explaining the different functions of its constituent smart contracts. 

Basic folder structure is as follows:

	Hypersurface (src)
	├── Hyperbase
	│   ├── claims
	│   │   ├── ClaimValidator.sol
	│   │   └── ClaimVerifiersRegistry.sol
	│   ├── identity
	│   │   ├── IdentityRegistry.sol
	│   │   └── Identity.sol
	│   └── domain
	│       └── DomainRegistry.sol
	├── Hypershare
	│   ├── compliance
	│   │   ├── ComplianceClaimsRequired.sol
	│   │   └── ComplianceLimitHolder.sol
	│   └── token
	│       └── TokenRegistry.sol
	├── Hypercores
	│   ├── ...
	│   └── ...
	│       
	└── Interface
		└── ...

### 1.0.0 Hyperbase is the home of all things **identity** related.

#### 1.1.0 [`identity`](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/identity) the core identity account and identity registries.

1.1.1 `IdentityRegistry.sol` stores the address of all the identity accounts within the protocol. The identity registry also stores and serves the corresponding country code for each identity, allowing for easy reference access. 

1.1.2 `Identity.sol` is an ERC-734 standard key-value pair store and ERC-735 claims, holder. The ERC-734 enables key management, allowing an arbitrary number of keys and permission levels to be added to an account, as well as managing the signature requirements for each type of operation. The ERC-734 claims holder stores “claims”, signed digital attestations that the identity has a given attribute. Claims in combination with an identity account create something equivalent to a digital ID card or passport.  The identity contract also features a number of execution functions that allow it to interact with other contracts on the blockchain. When calling the executeSigned function via a relay the Identity will refund a portion of tokens allowing for gasless single-token transactions. 

1.2.0 [`claims`](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/claims) are signed digital attestations that an identity has some property that are attached to an identity account. This directory is related to verifying claims in credential based interactions. 

1.2.1 `ClaimVerifiersRegistry.sol` stores the identity addresses of trusted claim verifiers. When establishing an identity has the requisite claims for a particular action, the protocol will also check that claims have come from a reputable source, recorded herein. 

1.2.2 `ClaimsValidator.sol` evaluates and verifies the veracity of claims attached to an identity account. If a token transfer requires a claim signed by a trusted verifier the ClaimsValidator references ClaimVerifiersRegistry.

1.3.0 [`sudomain`](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/sudomain) is currently empty but will be responsible for registering new  subdomains to an account. Currently assesing the relative merits of ENS vs the newer ERC-4834 standard.

### 2.0.0 Hypershare is the home of all things **equity** related. 

2.1.0 [`token`](https://github.com/blit-man/hypersurface-forge/src/Hypershare/token) is responsible for tracking and handling transfers of tokenised equity.

2.1.1. TokenRegistry.sol: is a permissioned multi-token asset registry based on the ERC-1155 standard. This important distinction strips away all unnecessary logic to create a lean, efficient, and flexible equity token implementation whereby, unlike an ERC-20 standard token, TokenRegistry can contain an infinite number of tokens within the same contract. This provides users with a single point of access to all assets within the Hypersurface ecosystem. TokenRegistry implements the transfer function in a conditional way, such that should the compliance checks fail, or the receiver not be eligible, the token transfer will revert. TokenRegistry also includes a number of fine-grain issuer control designed for permissioned assets, such as freezing and recovery. By virtue of its ERC-1155 compliance, TokenRegistry embeds agreements and structured agreement metadata in its URI tag.

2.2.0 [`compliance`](https://github.com/blit-man/hypersurface-forge/src/Hypershare/compliance) enforces on-chain transfer control thereby automating the process of compliance for users.

2.2.1 `ComplianceLimitHolder.sol` enforces limit-based transfer controls, such as ensuring the maximum number of holders has not been exceeded or that specific jurisdictional limits have not been exceeded. 

2.2.2 `ComplianceClaimsRequired.sol` stores claim topics that are required for holders, directly referencing the Identity claims of the receiver to verify that they have the appropriate credentials. 

## Next steps

The Hypersurface core protocol serves as the foundational infrastructure layer for subsequent development, be it a web application or further applications at the protocol-level extension addons. Rather than continuously upgrading, the protocol should be stabilised as quickly as possible. Primarily, the protocol provides an open standard that enables equity to be represented in a way that is uniform. The ideal is a minimalist control structure that enables a simple, effective base for subsequent development (see below, "Addons"). This enables it to be worked with quickly and safely, whether by Hypersurface, users, or other marketplace actors. As such Hypersurface in it's final form will most likely consist of a minimum of three core libraries: the protocol (this), the application, and the legal modules. If any areas of the core protocol will see significant change in the long-term, it will most likely be the on-chain compliance controls. By adding further sophistication to the compliance contract we will be able to reduce the general tedium of compliance and further increase transferability in a meaningful way for users.

## Addons

1. `ComplianceLimitHolder.sol` add team and restricted holder limits? i.e. Founders can't transfer more than n% per year?
2. More control logic for identities, DAO-style voting for angel networks? Are proposals directly merged with executions
3. Hypercores: equity token sales, voting, secondary markets, equity-backed loans, salary finance, on-chain incorporation, etc 