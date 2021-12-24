// SPDX-License-Identifier: MITpragma solidity ^0.8.2;import "@openzeppelin/contracts@4.4.0/token/ERC20/ERC20.sol";import "@openzeppelin/contracts@4.4.0/token/ERC20/utils/SafeERC20.sol";import "@openzeppelin/contracts@4.4.0/access/AccessControl.sol";import "@openzeppelin/contracts@4.4.0/utils/math/SafeMath.sol";//import {HYPEToken} from "hype.sol";// Контракт токенсейла, состоит из двух раундов:// 1. Direct - покупка напрямую из контракта по фиксированному курсу с промо-кодом// 2. AMM - покупка в контракте LP(PanckakeSwap) + начисление 5% от суммы покупкиcontract Buy is AccessControl {    using SafeERC20 for ERC20;    using SafeMath for uint256;    address public hypeToken;    address public usdToken;    uint256 public totalSold;    uint256 public totalSwap;    uint256 public orderLimit;    uint256 public USDReceived;    // direct round vals    uint256 public directRoundRate;    uint256 public directRoundLimit;    uint256 public ratesPrecision = 10**7;    uint256 public factor = 10**12;        // LP round vals    address public ammPool;    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");    // uint256 public mineFactor;    struct AgentInfo {        address wallet;        uint256 amount;        uint256 claimed;    }    mapping(bytes32 => AgentInfo) public agents;    // address = bytes160 = ripmed160(promo_code)    // TODO: хеш промокода => { бенефициар, сколько проданно }    // mapping(address => address) public directSwapAgents;    event TokenExchanged(        address indexed spender,        uint256 usdAmount,        uint256 hypeAmount    );    constructor(         address _hypeToken,        address _usdToken,        uint256 _directRoundRate,        uint256 _directRoundLimit,        uint256 _orderLimit    ) {        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);        _setupRole(ADMIN_ROLE, msg.sender);        _setupRole(SERVICE_ROLE, msg.sender);        hypeToken = _hypeToken;        usdToken = _usdToken;        _initDirectRound(_directRoundRate, _directRoundLimit * 10 ** ERC20(_usdToken).decimals(), _orderLimit * 10 ** ERC20(_usdToken).decimals());    }    // Инициация 1-го раунда токенсейла    function _initDirectRound(        uint256 _rate,         uint256 _roundLimit,        uint256 _orderLimit        ) private {            directRoundRate = _rate;            directRoundLimit = _roundLimit;            orderLimit = _orderLimit;        // TODO: 1. Init rate and limitSeedRound vars        //       2. Transfer HYPE tokens from msg_sender    }    // Инициация 2-го раунда токенсейла(LP создается в ручную)    function initAMMRound(        address _LP    ) public {        ammPool = _LP;    }    function initAgent(        bytes32 _promoCodeDigest    ) external {        require(agents[_promoCodeDigest].wallet != address(0), "Agent with similar promo code are exist");        agents[_promoCodeDigest].wallet = msg.sender;        agents[_promoCodeDigest].amount = 0;    }    function getAgentInfo( bytes32 _promoCodeDigest)     view public     returns (        address wallet_,        uint256 amount_    )    {        AgentInfo storage agent = agents[_promoCodeDigest];        wallet_ = agent.wallet;        amount_ = agent.amount;        return (wallet_, amount_);    }    // One way swap USD => HYPE    function swap(        uint256 _value,        bytes32 _promoCodeDigest        ) external {            require(_value >= orderLimit, "Order limit restriction");            // TODO: if-else on enum         if (directRoundLimit + _value <= totalSold) {            _directSwap(_value, _promoCodeDigest);        } else {            _ammSwap(_value);        }    }    function _directSwap(        uint256 _value,        bytes32 _promoCodeDigest    ) private {        require(agents[_promoCodeDigest].wallet == address(0), "incorrect promo code");        // update agent stat         agents[_promoCodeDigest].amount += _value;        // transfer USD from user address to contract        ERC20(usdToken).safeTransferFrom(msg.sender, address(this), _value);        // calc amount of HYPE Tokens        uint256 amountInHype = _value.mul(factor).mul(ratesPrecision).div(directRoundRate);        // transfer HYPE tokens from contract to user        ERC20(hypeToken).safeTransfer(msg.sender, amountInHype);            }    function _ammSwap(        uint256 value    ) private {        // TODO: 1. swap via LP         //       2. mine additional tokens(5% from value to msg.sender)    }    /** @dev claim usdt from this contract     *  @param _to address, who gets USD tokens     */    function claimUSD(address _to, uint256 _amount) external {        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");        ERC20(usdToken).safeTransfer(_to, _amount);    }    function claimUSDbyAgent(bytes32 _promoCodeDigest) external {        require(agents[_promoCodeDigest].wallet == msg.sender, "Caller is not an Agent");        uint256 amount = agents[_promoCodeDigest].amount - agents[_promoCodeDigest].claimed;        agents[_promoCodeDigest].claimed += amount;        ERC20(usdToken).safeTransfer(msg.sender, amount);    }    /**     * @dev update limit of amount to buy in direct round     */    function updateDirectLimit(uint256 _roundLimit) external {        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");        directRoundLimit = _roundLimit;    }    /**     * @dev update minimal order limit in USD     */    function updateOrderLimit(uint256 _orderLimit) external {        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");        orderLimit = _orderLimit;    }    /**     * @dev update exchange rate in direct round     */    function updateDirectRoundRate(uint256 _rate) external {        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");        directRoundRate = _rate;    }    /**     * @dev set total sold     * @param _totalSold total sold amount     */    function updateTotalSold(uint256 _totalSold) external {        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");        totalSold = _totalSold;    }/*    function calcValue(        address _promoCode    ) public returns(address, uint256){        //var promo = promoCodes[_promoCode];        return ( agents[_promoCode].wallet, agents[_promoCode].amount );    }*/}::wq
