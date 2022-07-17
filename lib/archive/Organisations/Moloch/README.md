STEAL THIS CODE

# Moloch

> Moloch the incomprehensible prison! Moloch the crossbone soulless jailhouse and Congress of sorrows! Moloch whose buildings are judgment! Moloch the vast stone of war! Moloch the stunned governments!
>
> Moloch whose mind is pure machinery! Moloch whose blood is running money! Moloch whose fingers are ten armies! Moloch whose breast is a cannibal dynamo! Moloch whose ear is a smoking tomb!

~ Allen Ginsberg, Howl

Moloch is a grant-making DAO / Guild and a radical experiment in voluntary incentive alignment to overcome the "tragedy of the commons". Our objective is to accelerate the development of public Ethereum infrastructure that many teams need but don't want to pay for on their own. By pooling our ETH, teams building on Ethereum can collectively fund open-source work we decide is in our common interest.

This documentation will focus on the Moloch DAO system design and smart contracts. For a deeper explanation of the philosophy behind Moloch, please read our [whitepaper](https://github.com/MolochVentures/Whitepaper/blob/master/Whitepaper.pdf) as well as the Slate Star Codex post, [Meditations on Moloch](http://slatestarcodex.com/2014/07/30/meditations-on-moloch/), which served as inspiration.

## Design Principles

In developing the Moloch DAO, we realized that the more Solidity we wrote, the greater the likelihood that we would lose everyone's money. In order to prioritize security, we took simplicity and elegance as our primary design principles. We consciously skipped many features, and the result is what we believe to be a Minimally Viable DAO.

## Overview

Moloch is described by two smart contracts:

1. `Moloch.sol` - Responsible for managing membership & voting rights, proposal submissions, voting, and processing proposals based on the outcomes of the votes.
2. `GuildBank.sol` - Responsible for managing Guild assets.

Moloch has a native asset called `shares`. Shares are minted and assigned when a new member is accepted into the Guild and provide voting rights on new membership proposals. They are non-transferrable, but can be *irreversibly* redeemed at any time to collect a proportional share of all ETH held by the Guild in the Guild Bank.

Moloch operates through the submission, voting on, and processing of a series of membership proposals. To combat spam, new membership proposals can only be submitted by existing members and require a 10 ETH deposit. Applicants who wish to join must find a Guild member to champion their proposal and have that member call `submitProposal` on their behalf. The membership proposal includes the number of shares the applicant is requesting, and either the amount of ETH the applicant is offering as tribute or a pledge that the applicant will complete some work that benefits the Guild.

All ETH offered as tribute is held in escrow by the `Moloch.sol` contract until the proposal vote is completed and processed. If a proposal vote passes, the applicant becomes a member, the shares requested are minted and assigned to them, and their tribute ETH is deposited into the `GuildBank.sol` contract. If a proposal vote is rejected, all tribute ETH is returned to the applicant. In either case, the 10 ETH deposit is returned to the member who submitted the proposal.

Proposals are voted on in the order they are submitted. The *voting period* for each proposal is 7 days. During the voting period, members can vote (only once, no redos) on a proposal by calling `submitVote`. There can be 5 proposals per day, so there can be a maximum of 35 proposals being voted on at any time (staggered by 4.8 hours). Proposal votes are determined by simple majority of votes cast on the proposal, with no quorum requirement.

At the end of the voting period, proposals enter into a 7 day *grace period* before the proposal is processed. The grace period gives members who voted **No** or didn't vote the opportunity to exit by calling the `ragequit` function and witdrawing their proportional share of ETH from the Guild Bank. Members who voted **Yes** must remain until the grace period expires and the proposal is processed, but only if the proposal passed. If the proposal failed, members who voted **Yes** can `ragequit` as well.

At the end of the grace period, proposals are processed when anyone calls `processProposal`. A 0.1 ETH reward is deducted from the proposal deposit and sent to the account to the address which calls `processProposal`.

#### Game Theory

By allowing Guild members to ragequit and exit at any time, Moloch protects its members from 51% attacks and from supporting proposals they vehemently oppose.

In the worst case, one or more Guild members who control >50% of the shares could submit a proposal to grant themselves a ridiculous number of new shares, thereby diluting all other members of their claims to the Guild Bank assets and effectively stealing from them. If this were to happen, everyone else would ragequit during the grace period and take their share of the Guild Bank assets with them, and the proposal would have no impact.

In the more likely case of a contentious vote, those who oppose strongly enough can leave and increase the funding burden on those who choose to stay. Let's say the Guild has 100 outstanding shares and $100M worth of ETH in the Guild Bank. If a project proposal requests 1 newly minted share (~$1M worth), the vote is split 50/50 with 100% voter turnout, and the 50 who voted **No** all ragequit and take their $50M with them, then the remaining members would be diluting themselves twice as much: 1/51 = ~2% vs. 1/101 = ~1%.

In this fashion, the ragequit mechanism also provides an interesting incentive in favor of Guild cohesion. Guild members are disincentivized from voting **Yes** on proposals that they believe will make other members ragequit. Those who do vote **Yes** on contentious proposals will be forced to additionally dilute themselves proportional to the fraction of Voting Shares that ragequit in response.

## Installation

To intall this project run `npm install`.

## Testing

To tests the contracts run `npm run test`.

To compute their code coverage run `npm run coverage`.

## Deploying an interacting with a Moloch DAO and a Pool

This project includes Buidler tasks for deploying and using DAOs and Pools.

### Deployment


#### Deploying a new DAO

Follow this instructions to deploy a new DAO:

1. Edit `buidler.config.js`, setting the values for `INFURA_API_KEY` and `MAINNET_PRIVATE_KEY`.
2. Edit `deployment-params.js`, setting your desired deployment parameters.
3. Run `npx buidler moloch-deploy --network mainnet`
4. Edit `buidler.config.js`, setting the address of the DAO in `networks.mainnet.deployedContracts.moloch`.

#### Deploying a new Pool

Follow this instructions to deploy a new Pool:

1. Edit `buidler.config.js`, setting the values for `INFURA_API_KEY` and `MAINNET_PRIVATE_KEY`.
2. Make sure you have the right address in `buidler.config.js`'s `networks.mainnet.deployedContracts.moloch` field.
3. Run `npx buidler pool-deploy --network mainnet --shares <shares> --tokens <tokens>` with the initial amount of tokens you want to donate to the pool, and how many shares you want in return.

### Interacting with the smart contracts

This project has tasks to work with DAOs and Pools. To use them, you should first follow this instructions:

1. Edit `buidler.config.js`, setting the values for `INFURA_API_KEY` and `MAINNET_PRIVATE_KEY`.
2. Make sure you have the right address in `buidler.config.js`'s `networks.mainnet.deployedContracts.moloch` field.
3. If you want to use a Pool, make sure you have the right address in `buidler.config.js`'s `networks.mainnet.deployedContracts.pool` field.

After following those instructions, you can run `npx buidler` to get a list with all the tasks:

```
$ npx buidler
AVAILABLE TASKS:

  clean                         Clears the cache and deletes all artifacts
  compile                       Compiles the entire project, building all artifacts
  console                       Opens a buidler console
  flatten                       Flattens and prints all contracts and their dependencies
  help                          Prints this message
  moloch-deploy                 Deploys a new instance of the Moloch DAO
  moloch-process-proposal       Processes a proposal
  moloch-ragequit               Ragequits, burning some shares and getting tokens back
  moloch-submit-proposal        Submits a proposal
  moloch-submit-vote            Submits a vote
  moloch-update-delegate        Updates your delegate
  pool-add-keeper               Adds a keeper
  pool-deploy                   Deploys a new instance of the pool and activates it
  pool-deposit                  Donates tokens to the pool
  pool-keeper-withdraw          Withdraw other users' tokens from the pool
  pool-remove-keeper            Removes a keeper
  pool-sync                     Syncs the pool
  pool-withdraw                 Withdraw tokens from the pool
  run                           Runs a user-defined script after compiling the project
  test                          Runs mocha tests
```


You can run `npx buidler help <task>` to get help about each tasks and their parameters. For example:

```
$ npx buidler help moloch-submit-proposal
Buidler version 1.0.0-beta.7

Usage: buidler [GLOBAL OPTIONS] moloch-submit-proposal --applicant <STRING> --details <STRING> --shares <STRING> --tribute <STRING>

OPTIONS:

  --applicant   The address of the applicant
  --details     The proposal's details
  --shares      The number of shares requested
  --tribute     The number of token's wei offered as tribute

moloch-submit-proposal: Submits a proposal

For global options help run: buidler help
```

# Moloch.sol

SECURITY NOTE: CALLING `APPROVE` ON THE MOLOCH CONTRACT IS NOT SAFE. ONLY `APPROVE` THE
AMOUNT OF WETH YOU INTEND TO SEND AS TRIBUTE, AND CONFIRM FOR YOURSELF THAT YOUR
APPLICATION PROPOSAL HAS THE CORRECT NUMBER OF SHARES REQUESTED. IF IT DOES
NOT, IT IS YOUR RESPONSIBILITY TO ABORT THE PROPOSAL IMMEDIATELY.

For more information about this, please see the documentation for the `abort`
function below.

## Data Structures

#### Global Constants
```
    uint256 public periodDuration; // default = 17280 = 4.8 hours in seconds (5 periods per day)
    uint256 public votingPeriodLength; // default = 35 periods (7 days)
    uint256 public gracePeriodLength; // default = 35 periods (7 days)
    uint256 public abortWindow; // default = 5 periods (1 day)
    uint256 public proposalDeposit; // default = 10 ETH (~$1,000 worth of ETH at contract deployment)
    uint256 public dilutionBound; // default = 3 - maximum multiplier a YES voter will be obligated to pay in case of mass ragequit
    uint256 public processingReward; // default = 0.1 - amount of ETH to give to whoever processes a proposal
    uint256 public summoningTime; // needed to determine the current period

    IERC20 public approvedToken; // approved token contract reference; default = wETH
    GuildBank public guildBank; // guild bank contract reference

    // HARD-CODED LIMITS
    // These numbers are quite arbitrary; they are small enough to avoid overflows when doing calculations
    // with periods or shares, yet big enough to not limit reasonable use cases.
    uint256 constant MAX_VOTING_PERIOD_LENGTH = 10**18; // maximum length of voting period
    uint256 constant MAX_GRACE_PERIOD_LENGTH = 10**18; // maximum length of grace period
    uint256 constant MAX_DILUTION_BOUND = 10**18; // maximum dilution bound
    uint256 constant MAX_NUMBER_OF_SHARES = 10**18; // maximum number of shares that can be minted
```

All deposits and tributes use the singular `approvedToken` set at contract deployment. In our case this will be wETH, and so we use wETH and ETH interchangably in this documentation.

#### Internal Accounting
```
    uint256 public totalShares = 0; // total shares across all members
    uint256 public totalSharesRequested = 0; // total shares that have been requested in unprocessed proposals
```

##### Proposals
The `Proposal` struct stores all relevant data for each proposal, and is saved in the `proposalQueue` array in the order it was submitted.
```
    struct Proposal {
        address proposer; // the member who submitted the proposal
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals
        uint256 sharesRequested; // the # of shares the applicant is requesting
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool processed; // true only if the proposal has been processed
        bool didPass; // true only if the proposal passed
        bool aborted; // true only if applicant calls "abort" fn before end of voting period
        uint256 tokenTribute; // amount of tokens offered as tribute
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 maxTotalSharesAtYesVote; // the maximum # of total shares encountered at a yes vote on this proposal
        mapping (address => Vote) votesByMember; // the votes on this proposal by each member
    }

    Proposal[] public proposalQueue;
```

##### Members
The `Member` struct stores all relevant data for each member, and is saved in the `members` mapping by the member's address.

```
    struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated
        uint256 shares; // the # of shares assigned to this member
        bool exists; // always true once a member has been created
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES
    }

    mapping (address => Member) public members;
    mapping (address => address) public memberAddressByDelegateKey;
```

The `exists` field is set to `true` when a member is accepted and remains `true` even if a member redeems 100% of their shares. It is used to prevent overwriting existing members (who may have ragequit all their shares).

For additional security, members can optionally change their `delegateKey` (used for submitting and voting on proposals) to a different address by calling `updateDelegateKey`. The `memberAddressByDelegateKey` stores the member's address by the `delegateKey` address.

##### Votes
The Vote enum reflects the possible values of a proposal vote by a member.
```
    enum Vote {
        Null, // default value, counted as abstention
        Yes,
        No
    }
```

## Modifiers

#### onlyMember
Checks that the `msg.sender` is the address of a member with at least 1 share.
```
    modifier onlyMember {
        require(members[msg.sender].shares > 0, "Moloch::onlyMember - not a member");
        _;
    }
```
Applied only to `ragequit` and `updateDelegateKey`.

#### onlyMemberDelegate
Checks that the `msg.sender` is the `delegateKey` of a member with at least 1 share.
```
    modifier onlyDelegate {
        require(members[memberAddressByDelegateKey[msg.sender]].shares > 0, "Moloch::onlyDelegate - not a delegate");
        _;
    }
```

Applied only to `submitProposal` and `submitVote`.

## Functions

### Moloch Constructor
1. Sets the `approvedToken` ERC20 contract reference.
2. Deploys a new `GuildBank.sol` contract and saves the reference.
3. Saves passed in values for global constants `periodDuration`, `votingPeriodLength`, `gracePeriodLength`, `abortWindow`, `proposalDeposit`, `dilutionBound`,  and `processingReward`.
4. Saves the start time of Moloch `summoningTime = now`.
5. Mints 1 share for the `summoner` and saves their membership.

```
    constructor(
        address summoner,
        address _approvedToken,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _abortWindow,
        uint256 _proposalDeposit,
        uint256 _dilutionBound,
        uint256 _processingReward
    ) public {
        require(summoner != address(0), "Moloch::constructor - summoner cannot be 0");
        require(_approvedToken != address(0), "Moloch::constructor - _approvedToken cannot be 0");
        require(_periodDuration > 0, "Moloch::constructor - _periodDuration cannot be 0");
        require(_votingPeriodLength > 0, "Moloch::constructor - _votingPeriodLength cannot be 0");
        require(_votingPeriodLength <= MAX_VOTING_PERIOD_LENGTH, "Moloch::constructor - _votingPeriodLength exceeds limit");
        require(_gracePeriodLength <= MAX_GRACE_PERIOD_LENGTH, "Moloch::constructor - _gracePeriodLength exceeds limit");
        require(_abortWindow > 0, "Moloch::constructor - _abortWindow cannot be 0");
        require(_abortWindow <= _votingPeriodLength, "Moloch::constructor - _abortWindow must be smaller than _votingPeriodLength");
        require(_dilutionBound > 0, "Moloch::constructor - _dilutionBound cannot be 0");
        require(_dilutionBound <= MAX_DILUTION_BOUND, "Moloch::constructor - _dilutionBound exceeds limit");
        require(_proposalDeposit >= _processingReward, "Moloch::constructor - _proposalDeposit cannot be smaller than _processingReward");

        approvedToken = IERC20(_approvedToken);

        guildBank = new GuildBank(_approvedToken);

        periodDuration = _periodDuration;
        votingPeriodLength = _votingPeriodLength;
        gracePeriodLength = _gracePeriodLength;
        abortWindow = _abortWindow;
        proposalDeposit = _proposalDeposit;
        dilutionBound = _dilutionBound;
        processingReward = _processingReward;

        summoningTime = now;

        members[summoner] = Member(summoner, 1, true, 0);
        memberAddressByDelegateKey[summoner] = summoner;
        totalShares = 1;

        emit SummonComplete(summoner, 1);
    }

```

### submitProposal
At any time, members can submit new proposals using their `delegateKey`.
1. Updates `totalSharesRequested` with the shares requested by the proposal.
2. Transfers the proposal deposit and tribute ETH to the `Moloch.sol` contract to be held in escrow until the proposal vote is completed and processed.
4. Calculates the proposal starting period, creates a new proposal, and pushes the proposal to the end of the `proposalQueue`.

```
    function submitProposal(
        address applicant,
        uint256 tokenTribute,
        uint256 sharesRequested,
        string memory details
    )
        public
        onlyDelegate
    {
        require(applicant != address(0), "Moloch::submitProposal - applicant cannot be 0");

        // Make sure we won't run into overflows when doing calculations with shares.
        // Note that totalShares + totalSharesRequested + sharesRequested is an upper bound
        // on the number of shares that can exist until this proposal has been processed.
        require(totalShares.add(totalSharesRequested).add(sharesRequested) <= MAX_NUMBER_OF_SHARES, "Moloch::submitProposal - too many shares requested");

        totalSharesRequested = totalSharesRequested.add(sharesRequested);

        address memberAddress = memberAddressByDelegateKey[msg.sender];

        // collect proposal deposit from proposer and store it in the Moloch until the proposal is processed
        require(approvedToken.transferFrom(msg.sender, address(this), proposalDeposit), "Moloch::submitProposal - proposal deposit token transfer failed");

        // collect tribute from applicant and store it in the Moloch until the proposal is processed
        require(approvedToken.transferFrom(applicant, address(this), tokenTribute), "Moloch::submitProposal - tribute token transfer failed");

        // compute startingPeriod for proposal
        uint256 startingPeriod = max(
            getCurrentPeriod(),
            proposalQueue.length == 0 ? 0 : proposalQueue[proposalQueue.length.sub(1)].startingPeriod
        ).add(1);

        // create proposal ...
        Proposal memory proposal = Proposal({
            proposer: memberAddress,
            applicant: applicant,
            sharesRequested: sharesRequested,
            startingPeriod: startingPeriod,
            yesVotes: 0,
            noVotes: 0,
            processed: false,
            didPass: false,
            aborted: false,
            tokenTribute: tokenTribute,
            details: details,
            maxTotalSharesAtYesVote: 0
        });

        // ... and append it to the queue
        proposalQueue.push(proposal);

        uint256 proposalIndex = proposalQueue.length.sub(1);
        emit SubmitProposal(proposalIndex, msg.sender, memberAddress, applicant, tokenTribute, sharesRequested);
    }
```

If there are no proposals in the queue, or if all the proposals in the queue have already started their respective voting period, then the proposal `startingPeriod` will be set to the next period. If there are proposals in the queue that have not started their voting period yet, the `startingPeriod` for the submitted proposal will be the next period after the `startingPeriod` of the last proposal in the queue.

Existing members can earn additional voting shares through new proposals if they are listed as the `applicant`.

### submitVote
While a proposal is in its voting period, members can submit their vote using their `delegateKey`.
1. Saves the vote on the proposal by the member address.
2. Based on their vote, adds the member's voting shares to the proposal `yesVotes` or `noVotes` tallies.
4. If the member voted **Yes** and this is now the highest index proposal they voted **Yes** on, update their `highestIndexYesVote`.
5. If the member voted **Yes** and this is now the most total shares that the Guild had during any **Yes** vote, update the proposal `maxTotalSharesAtYesVote`.

```
    function submitVote(uint256 proposalIndex, uint8 uintVote) public onlyDelegate {
        address memberAddress = memberAddressByDelegateKey[msg.sender];
        Member storage member = members[memberAddress];

        require(proposalIndex < proposalQueue.length, "Moloch::submitVote - proposal does not exist");
        Proposal storage proposal = proposalQueue[proposalIndex];

        require(uintVote < 3, "Moloch::submitVote - uintVote must be less than 3");
        Vote vote = Vote(uintVote);

        require(getCurrentPeriod() >= proposal.startingPeriod, "Moloch::submitVote - voting period has not started");
        require(!hasVotingPeriodExpired(proposal.startingPeriod), "Moloch::submitVote - proposal voting period has expired");
        require(proposal.votesByMember[memberAddress] == Vote.Null, "Moloch::submitVote - member has already voted on this proposal");
        require(vote == Vote.Yes || vote == Vote.No, "Moloch::submitVote - vote must be either Yes or No");
        require(!proposal.aborted, "Moloch::submitVote - proposal has been aborted");

        // store vote
        proposal.votesByMember[memberAddress] = vote;

        // count vote
        if (vote == Vote.Yes) {
            proposal.yesVotes = proposal.yesVotes.add(member.shares);

            // set highest index (latest) yes vote - must be processed for member to ragequit
            if (proposalIndex > member.highestIndexYesVote) {
                member.highestIndexYesVote = proposalIndex;
            }

            // set maximum of total shares encountered at a yes vote - used to bound dilution for yes voters
            if (totalShares > proposal.maxTotalSharesAtYesVote) {
                proposal.maxTotalSharesAtYesVote = totalShares;
            }

        } else if (vote == Vote.No) {
            proposal.noVotes = proposal.noVotes.add(member.shares);
        }

        emit SubmitVote(proposalIndex, msg.sender, memberAddress, uintVote);
```

### processProposal
After a proposal has completed its grace period, anyone can call `processProposal` to tally the votes and either accept or reject it. The caller receives 0.1 ETH as a reward.

1. Sets `proposal.processed = true` to prevent duplicate processing.
2. Update `totalSharesRequested` to deduct the proposal shares requested.
3. Determine if the proposal passed or failed based on the votes and whether or not the dilution bound was exceeded.
4. If the proposal passed (and was not aborted):
    4.1. If the applicant is an existing member, add the requested shares to their existing shares.
    4.2. If the applicant is a new member, save their data and set their default `delegateKey` to be the same as their member address.
        4.2.1. For new members, if the member address is taken by an existing member's `delegateKey` forcibly reset that member's `delegateKey` to their member address.
    4.3. Update the `totalShares`.
    4.4. Transfer the tribute ETH being held in escrow to the `GuildBank.sol` contract.
5. Otherwise (if the proposal failed or was aborted):
   5.1. Return all the tribute being held in escrow to the applicant.
6. Send the processing reward to the address that called this function.
7. Send the proposal deposit (minus the processing reward) back to the proposer.

```
    function processProposal(uint256 proposalIndex) public {
        require(proposalIndex < proposalQueue.length, "Moloch::processProposal - proposal does not exist");
        Proposal storage proposal = proposalQueue[proposalIndex];

        require(getCurrentPeriod() >= proposal.startingPeriod.add(votingPeriodLength).add(gracePeriodLength), "Moloch::processProposal - proposal is not ready to be processed");
        require(proposal.processed == false, "Moloch::processProposal - proposal has already been processed");
        require(proposalIndex == 0 || proposalQueue[proposalIndex.sub(1)].processed, "Moloch::processProposal - previous proposal must be processed");

        proposal.processed = true;
        totalSharesRequested = totalSharesRequested.sub(proposal.sharesRequested);

        bool didPass = proposal.yesVotes > proposal.noVotes;

        // Make the proposal fail if the dilutionBound is exceeded
        if (totalShares.mul(dilutionBound) < proposal.maxTotalSharesAtYesVote) {
            didPass = false;
        }

        // PROPOSAL PASSED
        if (didPass && !proposal.aborted) {

            proposal.didPass = true;

            // if the applicant is already a member, add to their existing shares
            if (members[proposal.applicant].exists) {
                members[proposal.applicant].shares = members[proposal.applicant].shares.add(proposal.sharesRequested);

            // the applicant is a new member, create a new record for them
            } else {
                // if the applicant address is already taken by a member's delegateKey, reset it to their member address
                if (members[memberAddressByDelegateKey[proposal.applicant]].exists) {
                    address memberToOverride = memberAddressByDelegateKey[proposal.applicant];
                    memberAddressByDelegateKey[memberToOverride] = memberToOverride;
                    members[memberToOverride].delegateKey = memberToOverride;
                }

                // use applicant address as delegateKey by default
                members[proposal.applicant] = Member(proposal.applicant, proposal.sharesRequested, true, 0);
                memberAddressByDelegateKey[proposal.applicant] = proposal.applicant;
            }

            // mint new shares
            totalShares = totalShares.add(proposal.sharesRequested);

            // transfer tokens to guild bank
            require(
                approvedToken.transfer(address(guildBank), proposal.tokenTribute),
                "Moloch::processProposal - token transfer to guild bank failed"
            );

        // PROPOSAL FAILED OR ABORTED
        } else {
            // return all tokens to the applicant
            require(
                approvedToken.transfer(proposal.applicant, proposal.tokenTribute),
                "Moloch::processProposal - failing vote token transfer failed"
            );
        }

        // send msg.sender the processingReward
        require(
            approvedToken.transfer(msg.sender, processingReward),
            "Moloch::processProposal - failed to send processing reward to msg.sender"
        );

        // return deposit to proposer (subtract processing reward)
        require(
            approvedToken.transfer(proposal.proposer, proposalDeposit.sub(processingReward)),
            "Moloch::processProposal - failed to return proposal deposit to proposer"
        );

        emit ProcessProposal(
            proposalIndex,
            proposal.applicant,
            proposal.proposer,
            proposal.tokenTribute,
            proposal.sharesRequested,
            didPass
        );
    }
```

The `dilutionBound` is a safety mechanism designed to prevent a member from facing a potentially unbounded grant obligation if they vote YES on a passing proposal and the vast majority of the other members ragequit before it is processed. The `proposal.maxTotalSharesAtYesVote` will be the highest total shares at the time of any **Yes** vote on the proposal. When the proposal is being processed, if members have ragequit and the total shares has dropped by more than the `dilutionBound` (default = 3), the proposal will fail. This means that members voting **Yes** will only be obligated to contribute *at most* 3x what the were willing to contribute their share of the proposal cost, if 2/3 of the shares ragequit.

### ragequit

At any time, so long as a member has not voted YES on any proposal in the voting period or grace period, they can *irreversibly* destroy some of their shares and receive a proportional sum of ETH from the Guild Bank.

1. Reduce the member's shares by the `sharesToBurn` being destroyed.
2. Reduce the total shares by the `sharesToBurn`.
3. Instruct the Guild Bank to send the member their proportional amount of ETH.

```
    function ragequit(uint256 sharesToBurn) public onlyMember {
        uint256 initialTotalShares = totalShares;

        Member storage member = members[msg.sender];

        require(member.shares >= sharesToBurn, "Moloch::ragequit - insufficient shares");

        require(canRagequit(member.highestIndexYesVote), "Moloch::ragequit - cant ragequit until highest index proposal member voted YES on is processed");

        // burn shares
        member.shares = member.shares.sub(sharesToBurn);
        totalShares = totalShares.sub(sharesToBurn);

        // instruct guildBank to transfer fair share of tokens to the ragequitter
        require(
            guildBank.withdraw(msg.sender, sharesToBurn, initialTotalShares),
            "Moloch::ragequit - withdrawal of tokens from guildBank failed"
        );

        emit Ragequit(msg.sender, sharesToBurn);
    }
```

### abort

One vulnerability found during audit was that interacting with the Moloch contract is that **calling "approve" with wETH is not safe**. When new applicants or existing members approve the transfer of some wETH to prepare for a proposal submission, any member could submit a proposal pointing to that applicant, `transferFrom` their approved tokens to Moloch, but maliciously input fewer shares than the applicant was expecting, effectively stealing from them. If this were to happen the applicant would find themselves appealing to the good will of the Guild members to vote **No** on the proposal and return the applicant's funds.

To address this, a proposal applicant can call `abort` to cancel the proposal, disable all future votes, and immediately receive their money back. The applicant has from the time the proposal is submitted to the time the `abortWindow` expires (1 day into the voting period) to do this.

Aborting a proposal does **not** immediately return the proposer's deposit. They are punished by still having to wait until the proposal has been processed to get their deposit back.

1. Set the proposal `tokenTribute` to zero.
2. Set the proposal `aborted` to true.
3. Return all tribute tokens to the `applicant`.
```
    function abort(uint256 proposalIndex) public {
        require(proposalIndex < proposalQueue.length, "Moloch::abort - proposal does not exist");
        Proposal storage proposal = proposalQueue[proposalIndex];

        require(msg.sender == proposal.applicant, "Moloch::abort - msg.sender must be applicant");
        require(getCurrentPeriod() < proposal.startingPeriod.add(abortWindow), "Moloch::abort - abort window must not have passed");
        require(!proposal.aborted, "Moloch::abort - proposal must not have already been aborted");

        uint256 tokensToAbort = proposal.tokenTribute;
        proposal.tokenTribute = 0;
        proposal.aborted = true;

        // return all tokens to the applicant
        require(
            approvedToken.transfer(proposal.applicant, tokensToAbort),
            "Moloch::processProposal - failing vote token transfer failed"
        );

        emit Abort(proposalIndex, msg.sender);
    }
```

Please check the audit report for the recommended fix. We agree that it makes sense, but in the interest of time we did not implement it. If any members are found abusing this vulnerability, we will prioritize deploying an upgraded Moloch contract which fixes it, and migrating to that.

### updateDelegateKey

By default, when a member is accepted their `delegateKey` is set to their member
address. At any time, they can change it to be any address that isn't already in
use, or back to their member address.

1. Resets the old `delegateKey` reference in the `memberAddressByDelegateKey`
   mapping.
2. Sets the reference for the new `delegateKey` to the member in the
   `memberAddressByDelegateKey` mapping.
3. Updates the `member.delegateKey`.


```
    function updateDelegateKey(address newDelegateKey) public onlyMember {
        require(newDelegateKey != address(0), "Moloch::updateDelegateKey - newDelegateKey cannot be 0");

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != msg.sender) {
            require(!members[newDelegateKey].exists, "Moloch::updateDelegateKey - cant overwrite existing members");
            require(!members[memberAddressByDelegateKey[newDelegateKey]].exists, "Moloch::updateDelegateKey - cant overwrite existing delegate keys");
        }

        Member storage member = members[msg.sender];
        memberAddressByDelegateKey[member.delegateKey] = address(0);
        memberAddressByDelegateKey[newDelegateKey] = msg.sender;
        member.delegateKey = newDelegateKey;

        emit UpdateDelegateKey(msg.sender, newDelegateKey);
    }
```

### Getters

#### max

Returns the maximum of two numbers.

```
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }
```

#### getCurrentPeriod

The difference between `now` and the `summoningTime` is used to figure out how many periods have elapsed and thus what the current period is.

```
    function getCurrentPeriod() public view returns (uint256) {
        return now.sub(summoningTime).div(periodDuration);
    }
```

#### getProposalQueueLength

Returns the length of the proposal queue.

```
    function getProposalQueueLength() public view returns (uint256) {
        return proposalQueue.length;
    }
```

#### canRagequit

Returns true if the `highestIndexYesVote` proposal has been processed.
```
    function canRagequit(uint256 highestIndexYesVote) public view returns (bool) {
        require(highestIndexYesVote < proposalQueue.length, "Moloch::canRagequit - proposal does not exist");
        return proposalQueue[highestIndexYesVote].processed;
    }
```

Note: At Moloch's inception, there will have been no proposals yet so the
`proposalQueue.length` will be 0. This means no one can ragequit until at least
one proposal has been processed. Fortunately, this only affects the summoner,
and because the Guild Bank will have no value until the first proposals have
passed anyways, it isn't a concern.

#### hasVotingPeriodExpired
```
    function hasVotingPeriodExpired(uint256 startingPeriod) public view returns (bool) {
        return getCurrentPeriod() >= startingPeriod.add(votingPeriodLength);
    }
```

#### getMemberProposalVote
```
    function getMemberProposalVote(address memberAddress, uint256 proposalIndex) public view returns (Vote) {
        require(members[memberAddress].exists, "Moloch::getMemberProposalVote - member doesn't exist");
        require(proposalIndex < proposalQueue.length, "Moloch::getMemberProposalVote - proposal doesn't exist");
        return proposalQueue[proposalIndex].votesByMember[memberAddress];
    }
```

# GuildBank.sol

## Data Structures

```
    ERC20 public approvedToken; // approved token contract reference
```

## Functions

### constructor
1. Sets the `approvedToken` and saves the contract reference. Called by the  `Moloch.sol` constructor.
```
    constructor(address approvedTokenAddress) public {
        approvedToken = ERC20(approvedTokenAddress);
    }
```

### withdraw

Is called by the owner - the `Moloch.sol` contract - in the `ragequit`
function.

1. Transfer a proportional share of ETH held by the guild bank to the
   provided `receiver` address.

```
    function withdraw(address receiver, uint256 shares, uint256 totalShares) public onlyOwner returns (bool) {
        uint256 amount = approvedToken.balanceOf(address(this)).mul(shares).div(totalShares);
        emit Withdrawal(receiver, amount);
        return approvedToken.transfer(receiver, amount);
    }
```

STEAL THIS CODE

# Moloch v2
![Worship Moloch](https://cdn.discordapp.com/attachments/583914506389028865/641047975421804584/2019-11-04_14.55.39.jpg)

> Moloch whose love is endless oil and stone! Moloch whose soul is electricity and banks! Moloch whose poverty is the specter of genius! Moloch whose fate is a cloud of sexless hydrogen! Moloch whose name is the Mind!

> Moloch! Moloch! Robot apartments! invisible suburbs! skeleton treasuries! blind capitals! demonic industries! spectral nations! invincible madhouses! granite cocks! monstrous bombs!

~ Allen Ginsberg, Howl

Moloch v2 is an upgraded version of MolochDAO that allows the DAO to acquire and spend multiple different tokens, instead of just one. It introduces the Guild Kick proposal type which allows members to forcibly remove another member (their assets are refunded in full). It also also allows for issuing non-voting shares in the form of Loot. Finally, v2 fixes the "unsafe approval" issue raised in the original [Nomic Labs audit](https://medium.com/nomic-labs-blog/moloch-dao-audit-report-f31505e85c70).

For a primer on Moloch v1, please visit the [original documentation](https://github.com/MolochVentures/moloch/tree/minimal-revenue/v1_contracts).

## Design Principles
In developing Moloch v2, we stuck with our ruthless minimalism, deviating as little as possible from the original while dramatically improving utility. We skipped many features again and believe our design represents a Minimally Viable For-Profit DAO, yet one flexible enough to support a variety of use decentralized cases, including venture funds, hedge funds, investment banks, and incubators.

## Overview

Moloch v2 is designed to extend MolochDAO's operations from purely single-token public goods grants-making to acquiring and spending (or investing in) an unlimited portfolio of assets.

Proposals in Moloch v2 now specify a **tribute token** and a **payment token**, which can be any whitelisted ERC20. Membership proposals which offer tribute tokens in exchange for shares can now offer any token, possibly helping balance the DAO portfolio. Grant proposals can now be in both shares and a stablecoin payment token to smooth out volatility risk, or even skip shares entirely to pay external contractors without awarding membership. Members can also propose *trades* to swap tokens OTC with the guild bank, which could be used for making investments, active portfolio management, selloffs, or just to top off a stablecoin reserve used to pay for planned expenses.

In addition to standard proposals above, there are two special proposals. The first is for whitelisting new tokens to be eligible as tribute, and the second is for removing DAO members via Guild Kick. Both follow the same voting mechanics as standard proposals (no quorum, simple majority rules).

### MolochLAO

In order to limit legal liability on members of a for-profit deployment of Moloch v2, the members may opt to form a [LAO](https://www.thelao.io/). LAOs are DAOs wrapped in a legally compliant entity, such as an LLC or C-Corp. The LAO can enter legal contracts, custody offchain assets (e.g. SAFTs), and distribute dividends. Investors in a LAO must be accredited, but service providers compensated in LAO shares can earn their shares of the LAO portfolio.

The current Moloch v2 contract standard was designed through a [collaborative effort](https://medium.com/@thelaoofficial/the-lao-joins-forces-with-moloch-dao-and-metacartel-to-begin-to-standardize-dao-related-smart-b6ee4b0db071) between MetaCartel, ConsenSys’s The LAO, and Moloch. The MetaCartel [Venture DAO](https://twitter.com/venture_dao) is expected to be the first deployment of Moloch v2 and blaze the trail for other for-profit DAOs to follow. Check out the Venture DAO [whitepaper](https://github.com/metacartel/MCV/blob/master/MCV-Whitepaper.md) for more information.

##### Security Tokens

To interface with offchain securities like SAFTs, the MolochLAO will issue security tokens that follow the Claims Token Standard [ERC-1843](https://github.com/ethereum/EIPs/issues/1843) and the Simple Restricted Token Standard [ERC-1404](https://github.com/ethereum/EIPs/issues/1404). Upon distribution of the SAFT tokens, the LAO custodian would send them to the claims token contract to be distributed to the claims token holders.

For equity, debt, or other revenue yielding securities the LAO custodian would receive the proceeds, liquidate to a token suitable for dividends (e.g. DAI) and then send the dividend tokens to the claims token contract to be distributed to the claims token holders.

Members that ragequit and receive their fraction of all LAO-held security claims tokens will still be able to use their various claims token to withdraw their dividends from each claims token contract.

Transfer restrictions will be enforced such that the security claims tokens can only be transferred to other DAO members, or other addresses whitelisted by the LAO admins.

## Installation

To intall this project run `npm install`.

## Testing

To tests the contracts run `npm run test`.

To compute their code coverage run `npm run coverage`.

## Deploying an interacting with a Moloch DAO and a Pool

This project includes Hardhat tasks for deploying and using DAOs and Pools.

#### Deploying a new DAO

Follow this instructions to deploy a new DAO:

1. Edit `hardhat.config.js`, setting the values for `INFURA_API_KEY` and `MAINNET_PRIVATE_KEY`.
2. Edit `deployment-params.js`, setting your desired deployment parameters.
3. Run `npx hardhat moloch-deploy --network mainnet`
4. Edit `hardhat.config.js`, setting the address of the DAO in `networks.mainnet.deployedContracts.moloch`.

#### Deploying a new Pool

Follow this instructions to deploy a new Pool:

1. Edit `hardhat.config.js`, setting the values for `INFURA_API_KEY` and `MAINNET_PRIVATE_KEY`.
2. Make sure you have the right address in `hardhat.config.js`'s `networks.mainnet.deployedContracts.moloch` field.
3. Run `npx hardhat pool-deploy --network mainnet --shares <shares> --tokens <tokens>` with the initial amount of tokens you want to donate to the pool, and how many shares you want in return.

### Interacting with the smart contracts

This project has tasks to work with DAOs and Pools. To use them, you should first follow this instructions:

1. Edit `hardhat.config.js`, setting the values for `INFURA_API_KEY` and `MAINNET_PRIVATE_KEY`.
2. Make sure you have the right address in `hardhat.config.js`'s `networks.mainnet.deployedContracts.moloch` field.
3. If you want to use a Pool, make sure you have the right address in `hardhat.config.js`'s `networks.mainnet.deployedContracts.pool` field.

After following those instructions, you can run `npx hardhat` to get a list with all the tasks:

```
$ npx hardhat
AVAILABLE TASKS:

  clean                         Clears the cache and deletes all artifacts
  compile                       Compiles the entire project, building all artifacts
  console                       Opens a hardhat console
  flatten                       Flattens and prints all contracts and their dependencies
  help                          Prints this message
  moloch-deploy                 Deploys a new instance of the Moloch DAO
  moloch-process-proposal       Processes a proposal
  moloch-ragequit               Ragequits, burning some shares and getting tokens back
  moloch-submit-proposal        Submits a proposal
  moloch-submit-vote            Submits a vote
  moloch-update-delegate        Updates your delegate
  pool-add-keeper               Adds a keeper
  pool-deploy                   Deploys a new instance of the pool and activates it
  pool-deposit                  Donates tokens to the pool
  pool-keeper-withdraw          Withdraw other users' tokens from the pool
  pool-remove-keeper            Removes a keeper
  pool-sync                     Syncs the pool
  pool-withdraw                 Withdraw tokens from the pool
  run                           Runs a user-defined script after compiling the project
  test                          Runs mocha tests
```


You can run `npx hardhat help <task>` to get help about each tasks and their parameters. For example:

```
$ npx hardhat help moloch-submit-proposal
hardhat version 2.0.0

Usage: hardhat [GLOBAL OPTIONS] moloch-submit-proposal --applicant <STRING> --details <STRING> --shares <STRING> --tribute <STRING>

OPTIONS:

  --applicant   The address of the applicant
  --details     The proposal's details
  --shares      The number of shares requested
  --tribute     The number of token's wei offered as tribute

moloch-submit-proposal: Submits a proposal

For global options help run: hardhat help
```

# Changelog v2

![Many
Molochs](https://cdn.discordapp.com/attachments/583914506389028865/643303589254529025/molochs.jpeg)

> To expect God to care about you or your personal values or the values of your civilization, that’s hubris.

> To expect God to bargain with you, to allow you to survive and prosper as long as you submit to Him, that’s hubris.

> To expect to wall off a garden where God can’t get to you and hurt you, that’s hubris.

> To expect to be able to remove God from the picture entirely…well, at least it’s an actionable strategy.

> I am a transhumanist because I do not have enough hubris not to try to kill God.

~ Scott Alexander, [Meditations on Moloch](http://slatestarcodex.com/2014/07/30/meditations-on-moloch/)

Moloch v2 is minimally different from Moloch v1, please read the [original documentation](https://github.com/MolochVentures/moloch/tree/master/v1_contracts) first, and then the changelog below.

## Moloch.sol

### General Changes

In order to circumvent Solidity's 16 parameter "stack too deep" error we
combined several proposal flags in the Proposal struct into the *flags* array.

```
struct Proposal {
  // ...
  bool[6] flags; // [sponsored, processed, didPass, cancelled, whitelist, guildkick]
  // 0. sponsored - true only if the proposal has been submitted by a member
  // 1. processed - true only if the proposal has been processed
  // 2. didPass - true only if the proposal passed
  // 3. cancelled - true only if the proposer called cancelProposal before a member sponsored the proposal
  // 4. whitelist - true only if this is a whitelist proposal, NOTE - tributeToken is target of whitelist
  // 5. guildkick - true only if this is a guild kick proposal, NOTE - applicant is target of guild kick
  // ...
}
```

### Pull Pattern

In order to mitigate a number of potential vulnerabilities around token transfers, all token transfers now follow the "pull pattern". This means that functions that would have previously called into an ERC20 token contract to move a balance now simply update an internal record of token balances instead. This prevents suddenly implemented token transfer restrictions from halting the proper execution of `Moloch.sol`, especially the `processProposal` function.

**As a result, the `GuildBank.sol` contract has been removed.**

Note - in this documentation we still refer to the "Guild Bank" as it remains a useful concept, but the balance is no longer tracked in the `GuildBank.sol` contract, but instead the `userTokenBalances[GUILD]` mapping of balances per token.

##### Globals
We add the nested mapping `userTokenBalances` to track balances by user & token. `userTokenBalances[userAddress][tokenAddress] = balance`.
```
    address public constant GUILD = address(0xdead);
    address public constant ESCROW = address(0xbeef);
    mapping (address => mapping(address => uint256)) public userTokenBalances;
```
The Guild balance is the sum of accepted tributes and would have previously been held in the `GuildBank.sol` contract, and the Escrow balance is the sum of pending tributes and would have previously been held on the `Moloch.sol` contract. A user's balance is the sum of token payments, ragequit proceeds, processor rewards, and returns proposal deposits that would have previously been automatically transferred to them, but is now held on their behalf until they withdraw.

##### `withdrawToken`

New function to withdraw a single token balance.

##### `withdrawTokens`

New function to withdraw multiple token balances at once. Can be called with `max = true` to withdraw 100% of each provided token address.

##### `processProposal`

No longer transfers payment tokens, returned deposits, and processor rewards automatically, instead updates internal token balances.

##### `ragequit` & `ragekick`

No longer transfers token balances automatically, instead updates internal token balances.

### Multi-Token Support

##### Proposal Struct
Add the following tribute/payment params to allow proposals to offer tribute and request payment in ERC20 tokens specified at the time. In theory they can be the same token, although that wouldn't make a lot of sense.
- add `uint256 tributeOffered` (renamed from `tokenTribute`)
- add `IERC20 tributeToken`
- add `uint256 paymentRequested`
- add `IERC20 paymentToken`

##### Globals
Track the whitelisted tokens in a mapping (to check if that token is on the whitelist) and an array (to iterate over them when ragequitting to give members a proportional share of all assets).
- add `mapping (address => IERC20) public tokenWhitelist`
- add `IERC20[] public approvedTokens`

##### `constructor`
- replace single `approvedToken` with an array: `approvedTokens`
- iterate through `approvedTokens` and save them to storage

##### `submitProposal`
- add tribute/payment token params
- enforce tribute/payment tokens are on whitelist
- save tribute/payment to proposal

##### `processProposal`
- auto-fail the proposal if guild bank doesn't have enough tokens for requested payment
- on successful proposal, update applicant's balance with payment tokens requested

##### `ragequit`
- withdraw proportional share of all whitelisted tokens, deducting from the internal guild bank balance and updating the user's internal balance

### Adding Tokens to Whitelist

##### Proposal Struct
- tributeToken -> token to whitelist
- proposal.flags[4] -> whitelist flag

##### Globals
- add `mapping (address => bool) public proposedToWhitelist` to prevent duplicate active token whitelist proposals

##### `submitWhitelistProposal`
- new function to propose adding a token to the whitelist
- enforces that the token address isn't null or already whitelisted
- saves a proposal with all other params set to null except the whitelist flag
  and `tributeToken` address (tributeToken acts as token to whitelist)

##### `processWhitelistProposal`
- new function to process whitelist proposals
- on a passing whitelist proposal, add the token to whitelist
- remove token from `proposedToWhitelist` so another proposal to whitelist the token can be made (assuming it failed)


### Submit -> Sponsor Flow
As Nomic Labs explained in their [audit report](https://medium.com/nomic-labs-blog/moloch-dao-audit-report-f31505e85c70), approving ERC20 tokens to Moloch is unsafe.

> Approving the Moloch DAO to transfer your tokens is, in general, unsafe. Users need to approve tokens to be a proposer or an applicant, but they can end up as the applicant of an unwanted proposal if someone attacks them, as explained in [MOL-L01].

> This also has an impact in the UX, as submitting a proposal requires three transactions (2 approvals, 1 submitProposal call). This is in contrast to one of the most common UX pattern for approval, which consists of only calling approve once, with MAX_INT as value. If someone were to use that pattern, she will be in a vulnerable situation.

To fix this, we change the submission process from only allowing members to submit proposals to allowing *anyone* to submit proposals but then only adding them to the proposal queue when a member **sponsors** the proposal.

##### Proposal Struct
- `address proposer` is now whoever calls `submitProposal` (can be non-member)
- add `address sponsor` which is the member that calls `sponsorProposal`
- add `cancelled` to indicate if the proposal has been cancelled by its proposer
- remove `aborted` which existed to address the unsafe approval vulnerability

##### Globals
- add `mapping (uint256 => Proposal) public proposals` to store all proposals by ID
- change `uint256[] public proposalQueue` to only store a reference to the proposal by its ID
- add `proposalCount` which monotonically increases on each proposal submission and acts as the ID

Note - as a result of this change, getting the proposal details from the proposal index changed across the codebase from `proposalQueue[proposalIndex]` to `proposals[proposalQueue[proposalIndex]]` as the former now only returns the proposal ID, which must be used to lookup the proposal details from the `proposals` mapping.

##### `submitProposal`
- saves proposal by ID, but **does not** add it to the `proposalQueue`
- transfers tribute tokens from the `msg.sender` (`proposer`)

Because tribute always comes from the `proposer` and not the `applicant`, there is never a situation where someone else can initiate an action to pull *your* tokens into Moloch, so you are safe to approve Moloch once for the maximum amount of any token you wish to offer as tribute.

##### `sponsorProposal`
- can only be called by a member
- sponsor escrows the proposal deposit
- checks that proposal has not been sponsored or cancelled
- checks to prevent duplicate `tokenWhitelist` and `guildKick` proposals
- adds the proposal to the `proposalQueue`

##### `processProposal`
- if failing, refunds escrowed tribute to the proposer, **not the applicant**

##### `cancelProposal`
If a proposal has been submitted but no members are interested in sponsoring it, the proposer needs a way to withdraw their escrowed tribute. They do this by calling `cancelProposal`, which they can only do before a member sponsors the proposal.
- can only be called by proposal `proposer` (whoever called `submitProposal`)
- checks that the proposal has not been already sponsored
- sets `cancelled` to true on the proposal
- returns escrowed tribute to the proposer

##### remove `abort` function
The abort functionality existed primarily to address the unsafe approval vulnerability by allowing applicants to abort unexpected and/or malicious proposals and have their tribute returned. However, with the new submit -> sponsor process, there is no risk to approved funds and the abort function and all references can be safely removed.

### Guild Kick
To allow the members to take risks on new members, we add the guild kick proposal type. The guild kick proposal, if it passes, puts the member in "jail" until all proposals they have voted YES on have been processed, forcing them to stay in the DAO and be party to any consequences of those proposals. When a member is jailed, 100% of their shares are converted to loot and thus they lose the ability to sponsor, vote on, or be the beneficiary (applicant) of any further proposals.

##### Proposal Struct
- applicant -> member to kick
- proposal.flags[5] -> guild kick flag

##### Member Struct
- add `jailed` -> the index of the proposal which jailed the member was jailed

##### Globals
- add `mapping (address => bool) public proposedToKick` to prevent duplicate active guild kick proposals

##### `submitGuildKickProposal`
- new function to propose kicking a member
- enforces that the member exists (has shares or loot)
- saves a proposal with all other params set to null except the guild kick flag
  and the `applicant` address (applicant acts as member to kick)

##### `processGuildKickProposal`
- a new function to process guild kick proposals
- on a passing guild kick proposal, convert 100% of the member's shares into loot and set `jailed` to the proposal index
- remove member address from `proposedToKick` so another proposal to kick the member can be made (assuming it failed)

### Ragekick
After a member has been jailed as a result of a passing guild kick proposal, once all the proposals they have voted YES on are processed, anyone can call the `ragekick` function to forcibly redeem the member's loot for their proportional share of the guild bank's tokens. This is effectively the same thing as the member calling `ragequit` themselves.

##### `ragekick`
- a new function to kick jailed members
- checks that member is jailed and has loot

### Loot
To allow the DAO to issue non-voting shares, we introduce the concept of Loot. Just like shares, loot is requested via proposal, issued to specific members and non-transferrable, and can be redeemed (via ragequit) on par with shares for a proportional fraction of assets in the Guild Bank. However, loot do not count towards votes and DAO members with *only* loot will not be able to sponsor proposals or vote on them. Non-shareholder members with loot will also be prevented from updating their delegate keys as they wouldn't be able to use them for anything anyways.

##### Proposal Struct
- add `lootRequested`
- update `maxTotalSharesAtYesVote` -> `maxTotalSharesAndLootAtYesVote`

##### Member Struct
- add `loot`

##### Globals
- add `totalLoot`
- update `totalSharesRequested` -> `totalSharesAndLootRequested`
- update `MAX_NUMBER_OF_SHARES` -> `MAX_NUMBER_OF_SHARES_AND_LOOT`
- add `onlyShareholder` modifier to be members with at least 1 share (not loot)
- update `onlyMember` modifier to be members with at least 1 share **or 1 loot**

##### `submitProposal`
- add `lootRequested` param

##### `sponsorProposal`
- check that `MAX_NUMBER_OF_SHARES_AND_LOOT` won't be exceeded
- update `totalSharesAndLootRequested`

##### `submitVote`
- update `maxTotalSharesAndLootAtYesVote` if necessary

##### `processProposal`
- update `totalSharesAndLootRequested`
- assign loot to member if proposal passes
- update `totalLoot` if proposal passes

Note - the dilution bound exists to prevent share based overpayment resulting from mass ragequit, and thus takes loot into account when calculating the anticipated dilution.

##### `ragequit`
- use updated `onlyMember` modifier (so loot holders can ragequit)
- add `lootToBurn` param

##### `safeRagequit`
- use updated `onlyMember` modifier (so loot holders can ragequit)
- add `lootToBurn` param

##### `updateDelegateKey`
- use `onlyShareholder` modifier to prevent loot-only members from updating delegate keys

### Deposit Token
To enforce consistency of the proposal deposits and processing fees (which were previously simply the sole `approvedToken`) we set a fixed `depositToken` at contract deployment.

##### Globals
- add `IERC20 public depositToken`

##### `constructor`
- save `depositToken` from the first value of the `approvedTokens` array

##### `sponsorProposal`
- collect proposal deposit from the sponsor

##### `processProposal`
- transfer processing reward in `depositToken` to whoever called `processProposal`
- return remaining deposit to proposer


![Goodbye](https://cdn.discordapp.com/attachments/583914506389028865/636359193154289687/image0.jpg)
[Goodbye](https://cdn.discordapp.com/attachments/583914506389028865/636359193154289687/image0.jpg)
