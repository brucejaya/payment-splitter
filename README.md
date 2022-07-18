# Hypersurface Protocol

Welcome to Hypersurface: a digital equity infrastructure for the internet age. Hypersurface reconfigures many of the control structures that businesses operate on using non-legal code based mechanisms. The core protocol enables lightweight, accessible and open digital equity on the blockchain, making the issuance, management, and transfer of tokenised assets as easy as sending email. 

## To-do
The core protocol is (remarkably) approaching complete MVP. It is not tidy. The protocol needs to go through the wash many, many times. However, the fundamental structure and core components are mostly present. Next steps are: 

1. Consider the relative strengths of an ERC-745 claims holder as compared to an ERC-780 claims registry
2. Bool based approvals in `identity/MultiSignature.sol` and identity is complete...
3. Same controls applied recursively to form organisation accounts?
4. Refactor Kali code base with support for Hypercores, particular focus on modularity and extensibility
5. Subdomains!
6. Factory, storage, upgradeability 

## Structure
The Hypersurface Protocol primarily consists of two core components, each with several sub-components split into folders.

Full folder structure is as follows:

	Hypersurface (src)
	├── Hyperbase
	│   ├── claims
	│   │   ├── ClaimValidator.sol
	│   │   └── ClaimVerifiersRegistry.sol
	│   └── identity
	│       ├── IdentityRegistry.sol
	│       └── Identity.sol
	├── Hypershare
	│   ├── compliance
	│   │   ├── ComplianceClaimsRequired.sol
	│   │   └── ComplianceLimitHolder.sol
	│   └── token
	│       └── TokenRegistry.sol
	└── Interface
		└── ...

## Directories
The Hypersurface Protocol primarily consists of two core components, each with several sub-components split into folders.

### 1. Hypershare is the home of all things **equity** related. 

1.1. [token](https://github.com/blit-man/hypersurface-forge/src/Hypershare/token) is a permissioned multi-token asset registry that has been structured with ERC-1155 as its core standard. This important distinction strips away all unnecessary logic to create a lean, efficient, and flexible equity token implementation which is deployed one-per-organisation (rather than one per asset). By virtue of its ERC-1155 compliance the token also embeds agreements and agreement metadata in it's URI tag.

1.2. [compliance](https://github.com/blit-man/hypersurface-forge/src/Hypershare/compliance) enforces on-chain transfer controls. Unlike other crypto assets, Hypershare transactions can fail for a variety of reasons. These reasons include the receiver not having verified KYC (`ComplianceClaimsRequired.sol`), assets having been locked or frozen, and economic and jurisdictional constraints such as holder, acquisition, and geographic limits (`ComplianceLimitHolder.sol`).

### 2. Hyperbase is the home of all things **identity** related.

2.1 [identity](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/identity) is both executions and claims holder, also includes sophisticated lightweight access controls, even for personal accounts.

2.2. [claims](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/claims) records verifiable digital claims from a Hyperbase and also records a registry of trusted claim issuers (e.g. KPMG, etc) and claim topics (e.g. accredited: y/n, nationality, etc.)

2.3. [subdomain](https://github.com/blit-man/hypersurface-forge/src/Hyperbase/subdomain) is currently empty but will be responsible for registering new ENS subdomains to an account e.g. "john.hype.surf", "acme.hype.surf". Currently looking for an adequate third-party library that interfaces with ENS.

## Next steps

The Hypersurface Protocol itself serves as the foundational infrastructure layer for subsequent development, be it a web application or further applications at the protocol-level extension addons. Rather than continuously upgrading, the protocol should be stabilised as quickly as possible. Primarily, the protocol provides an open standard that enables equity to be represented in a way that is uniform. The ideal is a minimalist control structure that enables a simple, effective base for subsequent development (see below, "Addons"). This enables it to be worked with quickly and safely, whether by Hypersurface, users, or other marketplace actors. As such Hypersurface in it's final form will most likely consist of a minimum of three core libraries: the protocol (this), the application, and the legal modules. If any areas of the core protocol will see significant change in the long-term, it will most likely be the on-chain compliance controls. By adding further sophistication to the compliance contract we will be able to reduce the general tedium of compliance and further increase transferability in a meaningful way for users.

## Addons

1. `ComplianceLimitHolder.sol` add team and restricted holder limits? i.e. Founders can't transfer more than n% per year?
2. More control logic for identities, DAO-style voting for angel networks? Are proposals directly merged with executions
3. Hypercores: equity token sales, voting, secondary markets, equity-backed loans, salary finance, on-chain incorporation, etc 
