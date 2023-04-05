// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);

    // latestRoundData should raise "No data present" if it does not have data to report,
    // instead of returning unset values which could be misinterpreted as actual reported values.

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract BetContract {
    using SafeMath for uint256;

    address immutable balaji;
    address immutable anon;

    IERC20 immutable WBTC;
    IERC20 immutable USDC;
    AggregatorV3Interface immutable priceFeed;
    AggregatorV3Interface immutable usdcPriceFeed;

    uint64 constant timeSpan = (90*24*3600);
    uint256 constant betThreshold = 10**6;

    uint256 constant amountOfWBTC = 10**8;
    uint256 constant amountOfUSDC = 10**12;

    uint64 public startTime;
    uint64 public dueTime;
    
    bool usdcDeposited;
    bool wbtcDeposited;
    bool betInitiated;

    event BetInitiated(bool _betInitiated, address indexed balaji, address indexed anon, uint64 dueTime);
    event BetSettled(bool _betSettled, address indexed _betWinner, uint64 _time, uint256 settlementPrice);
    event BetCancelled(bool _betCancelled);

    // usdc/usd ChainLink PriceFeed = '0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6'
    // btc/usd ChainLink PriceFeed = '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c'
    constructor(
        address _balaji, address _anon, address _wbtc,
        address _usdc, address _btcPriceFeed, address _usdcPriceFeed
    ) {

        balaji = _balaji;
        anon = _anon;

        priceFeed = AggregatorV3Interface(_btcPriceFeed);
        usdcPriceFeed = AggregatorV3Interface(_usdcPriceFeed);

        WBTC = IERC20(_wbtc);
        USDC = IERC20(_usdc);
    }

    modifier onlyBalaji() {
        require(msg.sender == balaji, "Must be Balaji's Eth address!");
        _;
    }

    modifier onlyAnon() {
        require(msg.sender == anon, "Must be Anon's Eth address!");
        _;
    }

    /**
     * @dev Deposit USDC.
     * An approve from the user must be called to allow this smart contract spend the token.
     *
     * Requirements:
     *
     * - `betInitiated` must be false.
     * - `amount` can not be zero.
     * - Approval must be gotten from user to spend USDC tokens.
     *
     * @notice Balaji deposits USDC, and the bet is initiated if Anon has deposited WBTC.
     *
     * Emits a {BetInitiated} event if both has deposited.
     */
    function depositUSDC() external onlyBalaji payable {
        require(betInitiated == false, "It's not possible to deposit more funds");
        // Approve the transfer of USDC from Balaji's wallet (Must be done by Balaji).
        USDC.transferFrom(balaji, address(this), amountOfUSDC);
        usdcDeposited = true;

        if (wbtcDeposited) {
            betInitiated = true;
            startTime = uint64(block.timestamp);
            dueTime = calcEndTime();
            emit BetInitiated(true, balaji, anon, dueTime);
        }
    }

    /**
     * @dev Deposit WBTC.
     * An approve from the user must be called to allow this smart contract spend the token.
     *
     * Requirements:
     *
     * - `betInitiated` must be false.
     * - `amount` can not be zero.
     * - Approval must be gotten from user to spend WBTC tokens.
     *
     * @notice Anon deposits WBTC, and the bet is initiated if Balaji has deposited USDC.
     *
     * Emits a {BetInitiated} event if both has deposited.
     */
    function depositWBTC() external onlyAnon payable {
        require(betInitiated == false, "It's not possible to deposit more funds");
        // Approve the transfer of USDC from Balaji's wallet (Must be done by Balaji).
        WBTC.transferFrom(anon, address(this), amountOfWBTC);
        wbtcDeposited = true;

        if (usdcDeposited) {
            betInitiated = true;
            startTime = uint64(block.timestamp);
            dueTime = calcEndTime();
            emit BetInitiated(true, balaji, anon, dueTime);
        }
    }

    /// @notice Calculate the dueTime as from when the bet was initiated.
    function calcEndTime() internal view returns(uint64){
        require(betInitiated, "The bet has not been Initiated");
        return (uint64(block.timestamp) + timeSpan);
    }

    /// @notice Bet can be cancelled if only one party has deposited and any of them decides to opt out.
    /// @notice Emits {BetCancelled} event.
    function cancelBeforeInitiation() external {
        require(msg.sender == anon || msg.sender == balaji, "This must be from either party!");
        require(!betInitiated, "Cannot cancel, bet already locked in!");

        if (usdcDeposited) {
            usdcDeposited = false;
            USDC.transfer(balaji, USDC.balanceOf(address(this)));
        }

        if (wbtcDeposited) {
            wbtcDeposited = false;
            WBTC.transfer(anon, WBTC.balanceOf(address(this)));
        }
        emit BetCancelled(true);
    }
    
    /**
     * @dev Transfer the funds to the winner of the bet.
     *
     * Requirements:
     *
     * - `betInitiated` must be true.
     * - Must be the due date or after.
     *
     * @notice If WBTC > 1000000, Balaji wins, else, Anon wins the bet.
     *
     * Emits a {BetSettled} event with the winner address.
     */
    function settleBet() external payable {
        require(betInitiated == true, "There is no valid bet");
        require(block.timestamp >= dueTime && dueTime > 0, "Bet time not elapsed");

        betInitiated = false;
        uint256 wbtcPrice = btcPriceInUSDC();

        address betWinner;
        if (wbtcPrice >= betThreshold) {
            betWinner = balaji;
        } else {
            betWinner = anon;
        }

        require(betWinner != address(0), 'cannot transfer funds to burner wallet');
        WBTC.transfer(betWinner, WBTC.balanceOf(address(this)));
        USDC.transfer(betWinner, USDC.balanceOf(address(this)));

        emit BetSettled(true, betWinner, uint64(block.timestamp), wbtcPrice);
    }

    /// @notice Get BTC price relative to USD from ChainLink oracle.
    function getBTCPriceFeed() public view returns(uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /// @notice Get USDC price relatve to USD from ChainLink oracle.
    function getUSDCPriceFeed() public view returns(uint256) {
        (,int256 usdcPrice,,,) = usdcPriceFeed.latestRoundData();
        return uint256(usdcPrice);
    }

    /// @notice Calculate BTC price relatve to USDC.
    function btcPriceInUSDC() public view returns(uint256) {
        uint256 btcPriceFeed = getBTCPriceFeed();
        uint256 btcPrice = btcPriceFeed.div(getUSDCPriceFeed());
        return btcPrice;
    }
}