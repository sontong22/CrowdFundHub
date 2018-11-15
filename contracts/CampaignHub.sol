pragma solidity ^0.4.24;

import './SafeMath.sol';
import './Ownable.sol'; 
import './TimedCampaign.sol';
import './MatchTimedCampaign.sol';
import './ConstMatchTimedCampaign.sol';
import './RateMatchTimedCampaign.sol';
import './ChainlinkLib.sol';
import './Chainlinked.sol';

contract CampaignHub is Chainlinked, Ownable {
    using SafeMath for uint256;

    address public owner;
    uint256 public currentPrice;
    
    TimedCampaign[] public campaigns;

    address constant ROPSTEN_ENS = 0x112234455C3a32FD11230C42E7Bccd4A84e02010;
    bytes32 constant ROPSTEN_CHAINLINK_ENS = 0xead9c0180f6d685e43522fcfe277c2f0465fe930fb32b5b415826eacf9803727;

     event NewTimedCampaign(
        string title, 
        uint256 openingTime, 
        uint256 closingTime, 
        address addr, 
        address creator
    );
    
    event RequestEthereumPriceFulfilled(
        bytes32 indexed requestId,
        uint256 indexed price
    );

    // region Constructor

    constructor() Ownable() public {
        owner = msg.sender;
        newChainlinkWithENS(ROPSTEN_ENS, ROPSTEN_CHAINLINK_ENS);
    }
    
    // endregion Constructor


    // region Public Functions

    /**
    * Create a new Campaign contract.
    * cpType = 1: TimedCampaign.
    * cpType = 2: ConstMatchTimedCampaign.
    * cpType = 3: RateMatchTimedCampaign.
    */
    function createCampaign(
        string _title, 
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _matchRate,
        address _beneficiary,
        uint256 cpType
        ) external returns(address) {
        address addr;
         if (cpType == 1) {
            TimedCampaign tp = new TimedCampaign(
                _title, _openingTime, _closingTime, _beneficiary, address(this));
            campaigns.push(tp);
            addr = address(tp);
        } else if (cpType == 2) {
            ConstMatchTimedCampaign cp = new ConstMatchTimedCampaign(
                _title, _openingTime, _closingTime, _matchRate, _beneficiary, address(this));
            campaigns.push(cp);
            addr = address(cp);
        } else if (cpType == 3) {
            RateMatchTimedCampaign rp = new RateMatchTimedCampaign(
                _title, _openingTime, _closingTime, _matchRate, _beneficiary, address(this));
            campaigns.push(rp);
            addr = address(rp);
        }
        emit NewTimedCampaign(_title, _openingTime, _closingTime, addr, msg.sender);
        
        return addr;
    }

    /**
    * Allow sender to contribute to a Campaign by it's address. 
    * Calls the fundDirect() payable function in the Campaign contract
    * and passes on all value attached to this function call.
    */
    function contributeDirect(address _campaignAddress) external payable {
        _preValidateContribution(msg.sender, msg.value);
        TimedCampaign deployedCampaign = TimedCampaign(_campaignAddress);
        deployedCampaign.fundDirect.value(msg.value)(msg.sender);
    }
    
    /**
    * Allow sender to contribute to a Campaign by it's address. 
    * Calls the fundVault() payable function in the Campaign contract
    * and passes on all value attached to this function call.
    */
    function contributeVault(address _campaignAddress) external payable {
        _preValidateContribution(msg.sender, msg.value);
        MatchTimedCampaign deployedCampaign = MatchTimedCampaign(_campaignAddress);
        deployedCampaign.fundVault.value(msg.value)(msg.sender);
    }
    
    /**
    * Allow sender to declare a condition before contributing 
    * to a Campaign by it's address. The condition here is the price 
    * of ETH to USD at current time must be higher than given value. 
    * Calls the fundVault() payable function in the Campaign contract
    * and passes on all value attached to this function call.
    */
    function contributeVaultWithCondition(address _campaignAddress, uint256 _cond)
        external 
        payable 
    {
        _preValidateContribution(msg.sender, msg.value);
        MatchTimedCampaign deployedCampaign = MatchTimedCampaign(_campaignAddress);
        
        // Ethereum price in USD
        requestEthereumPrice("2216dd2bf5464687a05ded0b844e200c", "USD");
        
        // If condition is met, forward fund to specified campaign
        require(_cond <= currentPrice);
        deployedCampaign.fundVault.value(msg.value)(msg.sender);
    }
    
    /**
     * Allow sender to claim their refund to a Campaign by it's address.'
     * Calls the refund() function in the Campaign contract.
     */
    function refund(address _campaignAddress) external {
        MatchTimedCampaign deployedCampaign = MatchTimedCampaign(_campaignAddress);
        deployedCampaign.refund(msg.sender);
    }
    
    /**
     * Allow the beneficiary to claim the fund of a Campaign by it's address.'
     * Calls the payOut() function in the Campaign contract.
     */
    function payOut(address _campaignAddress) external {
        TimedCampaign deployedCampaign = TimedCampaign(_campaignAddress);
        deployedCampaign.payOut(msg.sender);
    }
    
    // endregion Public Functions
    
    
    // region Oracle Functions
    
    function requestEthereumPrice(string _jobId, string _currency) public onlyOwner {
        ChainlinkLib.Run memory run = newRun(stringToBytes32(_jobId), this, "fulfillEthereumPrice(bytes32,uint256)");
        run.add("url", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,EUR,JPY");
        string[] memory path = new string[](1);
        path[0] = _currency;
        run.addStringArray("path", path);
        run.addInt("times", 100);
        chainlinkRequest(run, LINK(1));
    }

    function fulfillEthereumPrice(bytes32 _requestId, uint256 _price)
        public
        checkChainlinkFulfillment(_requestId)
    {
        emit RequestEthereumPriceFulfilled(_requestId, _price);
        currentPrice = _price;
    }

    function updateChainlinkAddresses() public onlyOwner {
        newChainlinkWithENS(ROPSTEN_ENS, ROPSTEN_CHAINLINK_ENS);
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkToken();
    }
  
    function getOracle() public view returns (address) {
        return oracleAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkToken());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    // endregion Oracle Functions
    
    
    // region Get View Functions
    
    function isBeneficiary(address _campaignAddress) public view returns(bool) {
        TimedCampaign deployedCampaign = TimedCampaign(_campaignAddress);
        return msg.sender == deployedCampaign.beneficiary();
    }
    
    function getContributionToVault(address _campaignAddress) public view returns(uint256) {
        MatchTimedCampaign deployedCampaign = MatchTimedCampaign(_campaignAddress);
        return deployedCampaign.getContributionToVault(msg.sender);
    }
    
    function getTotalFund(address _campaignAddress) public view returns(uint256) {
        TimedCampaign deployedCampaign = TimedCampaign(_campaignAddress);
        return deployedCampaign.totalFund();
    }
    
     function getTotalMatchVault(address _campaignAddress) public view returns(uint256) {
        MatchTimedCampaign deployedCampaign = MatchTimedCampaign(_campaignAddress);
        return deployedCampaign.totalMatchVault();
    }
    
     function getCurrentFund(address _campaignAddress) public view returns(uint256) {
        MatchTimedCampaign deployedCampaign = MatchTimedCampaign(_campaignAddress);
        return deployedCampaign.currentMatchVault();
    }
    
    function isOpen(address _campaignAddress) public view returns(bool) {
        TimedCampaign deployedCampaign = TimedCampaign(_campaignAddress);
        return deployedCampaign.isOpen();
    }
    
    // endregion Get View Functions
    
    
    // region Condition validation Functions
    
    /**
     * Pre-validation of an incoming contribution.
     */
    function _preValidateContribution(address _contributor, uint256 _amount) internal pure {
        require(_contributor != address(0));
        require(_amount != 0);
    }
    
    // endregion Condition validation Functions
}