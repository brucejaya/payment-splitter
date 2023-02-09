// SPDX-License-Identifier: MIT
import '@chainlink/contracts/src/v0.6/VRFConsumerBase.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

pragma solidity 0.8.1;

contract Oddsgame is VRFConsumerBase, Ownable, ReentrancyGuard {
    
    ////////////////
    // CONTRACTS
    ////////////////

    using SafeERC20 for IERC20;

    ////////////////
    // STATES
    ////////////////
    
    bool public paused = false;
    
    address public constant LINK_TOKEN = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;// polygon 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address public constant VRF_COORDINATOR = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;// polygon 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    bytes32 public constant KEY_HASH = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;// polygon 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    
    uint public chainlinkFee = 0.1 * 10 ** 18;
    uint public houseEdgePercent = 1;
    
    uint constant MAX_MODULO = 100;
    uint constant MAX_MASK_MODULO = 40;
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    uint public cumulativeDeposit;
    uint public cumulativeWithdrawal;

    uint public wealthTaxIncrementThreshold = 3000 ether;
    uint public wealthTaxIncrementPercent = 1;

    uint public minBetAmount = 0.001 ether;
    uint public maxBetAmount = 100 ether;

    uint public maxProfit = 3000 ether;

    uint public lockedInBets;

    struct Bet {
        uint amount;
        uint8 modulo;
        uint8 rollUnder;
        uint40 mask;
        uint placeBlockNumber;
        address payable gambler;
        bool isSettled;
        uint outcome;
        uint winAmount;
        uint randomNumber;
    }

    Bet[] public bets;

    uint public betsLength;

    mapping(bytes32 => uint) public betMap;

    ////////////////
    // EVENTS
    ////////////////

    event BetPlaced(uint indexed betId, address indexed gambler);
    event BetSettled(uint indexed betId, address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollUnder, uint40 mask, uint outcome, uint winAmount);
    event BetRefunded(uint indexed betId, address indexed gambler);

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor() VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN) public {}
   
    //////////////////////////////////////////////
    // BET RESOLUTION
    //////////////////////////////////////////////

    function getDiceWinAmount(
        uint amount,
        uint modulo,
        uint rollUnder
    )
        private
        view
        returns (uint winAmount)
    {
        require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");
        uint houseEdge = amount * (houseEdgePercent + getWealthTax(amount)) / 100;
        winAmount = (amount - houseEdge) * modulo / rollUnder;
    }

    function placeBet(
        uint betMask,
        uint modulo
    )
        external
        payable
        nonReentrant
    {
        uint amount = msg.value;

        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK in contract.");
        require(modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require(amount >= minBetAmount && amount <= maxBetAmount, "Bet amount should be within range.");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        uint rollUnder;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        }
        else {
            require(betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

        uint possibleWinAmount = getDiceWinAmount(amount, modulo, rollUnder);
        require(possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");
        require(lockedInBets + possibleWinAmount <= address(this).balance, "Unable to accept bet due to insufficient funds");
        lockedInBets += possibleWinAmount;

        bets.push(Bet(
            {
                amount: amount,
                modulo: uint8(modulo),
                rollUnder: uint8(rollUnder),
                mask: uint40(mask),
                placeBlockNumber: block.number,
                gambler: msg.sender,
                isSettled: false,
                outcome: 0,
                winAmount: 0,
                randomNumber: 0
            }
        ));

        bytes32 requestId = requestRandomness(KEY_HASH, chainlinkFee);
        betMap[requestId] = betsLength;
        emit BetPlaced(betsLength, msg.sender);
        betsLength++;
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint randomness
    )
        internal
        override
    {
        settleBet(requestId, randomness);
    }

    function settleBet(
        bytes32 requestId,
        uint randomNumber
    )
        internal
        nonReentrant
    {
        uint betId = betMap[requestId];
        Bet storage bet = bets[betId];
        uint amount = bet.amount;
        
        require(amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already"); // Check that bet is not settled yet

        uint outcome = randomNumber % bet.modulo;
        uint possibleWinAmount = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        uint winAmount = 0;

        if (bet.modulo <= MAX_MASK_MODULO) {
            if ((2 ** outcome) & bet.mask != 0) {
                winAmount = possibleWinAmount;
            }
        } else {
            if (outcome < bet.rollUnder) {
                winAmount = possibleWinAmount;
            }
        }

        emit BetSettled(betId, bet.gambler, amount, uint8(bet.modulo), uint8(bet.rollUnder), bet.mask, outcome, winAmount);

        lockedInBets -= possibleWinAmount;

        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.randomNumber = randomNumber;
        bet.outcome = outcome;

        if (winAmount > 0) {
            bet.gambler.transfer(winAmount);
        }
    }

    function refundBet(
        uint betId
    )
        external
        nonReentrant
        payable
    {
        Bet storage bet = bets[betId];

        require(bet.amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already."); // Check that bet is still open
        require(block.number > bet.placeBlockNumber + 43200, "Wait after placing bet before requesting refund.");

        uint possibleWinAmount = getDiceWinAmount(bet.amount, bet.modulo, bet.rollUnder);
        lockedInBets -= possibleWinAmount;
        bet.isSettled = true;
        bet.winAmount = bet.amount;
        bet.gambler.transfer(bet.amount);

        emit BetRefunded(betId, bet.gambler);
    }
 
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    function setHouseEdge(
        uint _houseEdgePercent
    )
        external
        onlyOwner
    {
        houseEdgePercent = _houseEdgePercent;
    }

    function setChainlinkFee(
        uint _chainlinkFee
    )
        external
        onlyOwner
    {
        chainlinkFee = _chainlinkFee;
    }

    function setMinBetAmount(
        uint _minBetAmount
    )
        external
        onlyOwner
    {
        minBetAmount = _minBetAmount;
    }

    function setMaxBetAmount(
        uint _maxBetAmount
    )
        external
        onlyOwner
    {
        require(_maxBetAmount < 5000000 ether, "maxBetAmount must be a sane number");
        maxBetAmount = _maxBetAmount;
    }

    function setMaxProfit(
        uint _maxProfit
    )
        external
        onlyOwner
    {
        require(_maxProfit < 50000000 ether, "maxProfit must be a sane number");
        maxProfit = _maxProfit;
    }

    function setWealthTaxIncrementPercent(
        uint _wealthTaxIncrementPercent
    )
        external
        onlyOwner
    {
        wealthTaxIncrementPercent = _wealthTaxIncrementPercent;
    }

    function setWealthTaxIncrementThreshold(
        uint _wealthTaxIncrementThreshold
    )
        external
        onlyOwner
    {
        wealthTaxIncrementThreshold = _wealthTaxIncrementThreshold;
    }

    function getWealthTax(
        uint amount
    )
        private
        view
        returns (uint wealthTax)
    {
        wealthTax = amount / wealthTaxIncrementThreshold * wealthTaxIncrementPercent;
    }
 
    //////////////////////////////////////////////
    // OWNER FUNCTIONS
    //////////////////////////////////////////////

    function pauseContract()
        external
        onlyOwner
    {
        if (paused) {
            paused = false;
        }
        else {
            paused = true;
        }
    }

    function balanceETH()
        external
        view
        returns (uint)
    {
        return address(this).balance;
    }

    function balanceLINK()
        external
        view
        returns (uint)
    {
        return LINK.balanceOf(address(this));
    }

    function withdrawFunds(
        address payable beneficiary,
        uint withdrawAmount
    )
        external
        onlyOwner
    {
        require(withdrawAmount <= address(this).balance, "Withdrawal amount larger than balance.");
        require(withdrawAmount <= address(this).balance - lockedInBets, "Withdrawal amount larger than balance minus lockedInBets");
        beneficiary.transfer(withdrawAmount);
        cumulativeWithdrawal += withdrawAmount;
    }

    function withdrawTokens(
        address token_address
    )
        external
        onlyOwner
    {
        IERC20(token_address).safeTransfer(owner(), IERC20(token_address).balanceOf(address(this)));
    }
    
    function withdrawAll()
        external
        onlyOwner
    {
        uint withdrawAmount = address(this).balance - lockedInBets;
        cumulativeWithdrawal += withdrawAmount;
        msg.sender.transfer(withdrawAmount);
        IERC20(LINK_TOKEN).safeTransfer(owner(), IERC20(LINK_TOKEN).balanceOf(address(this)));
    }
    
    fallback()
        external
        payable
    {
        cumulativeDeposit += msg.value;
    }
    receive()
        external
        payable
    {
        cumulativeDeposit += msg.value;
    }
}