pragma solidity ^0.4.4;

import './TimedCampaign.sol';
import './ConstMatchTimedCampaign.sol';
import './RateMatchTimedCampaign.sol';
import './SafeMath.sol';

contract CampaignHub {
    using SafeMath for uint256;

    address public owner;
    uint256 public numOfCampaigns;

    event NewCampaign(string title, uint256 openingTime, uint256 closingTime, address addr, address creator);

    Campaign[] public campaigns;

    mapping(address => uint) public campaignAddressToId;


    // region Constructor

    constructor() public {
        owner = msg.sender;
        numOfCampaigns = 0;
    }
    
    // endregion Constructor


    // region Public Functions

    /**
    * Create a new Campaign contract.
    * cpType = 1: TimedCampaign.
    * cpType = 1: ConstMatchTimedCampaign.
    * cpType = 2: RateMatchTimedCampaign.
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
        campaignAddressToId[addr] = numOfCampaigns;
        numOfCampaigns++;
        emit NewCampaign(_title, _openingTime, _closingTime, addr, msg.sender);
        
        return addr;
    }

    /**
    * Allow sender to contribute to a Campaign by it's address. 
    * Calls the fundDirect() payable function in the Campaign contract
    * and passes on all value attached to this function call.
    */
    function contributeDirect(address _campaignAddress) external payable {
        _preValidateContribution(msg.sender, msg.value);
        Campaign deployedCampaign = Campaign(_campaignAddress);
        isDeployedByHub(deployedCampaign.campaignHub());
        deployedCampaign.fundDirect.value(msg.value)(msg.sender);
    }
    
    /**
    * Allow sender to contribute to a Campaign by it's address. 
    * Calls the fundVault() payable function in the Campaign contract
    * and passes on all value attached to this function call.
    */
    function contributeVault(address _campaignAddress) external payable {
        _preValidateContribution(msg.sender, msg.value);
        Campaign deployedCampaign = Campaign(_campaignAddress);
        isDeployedByHub(deployedCampaign.campaignHub());
        deployedCampaign.fundVault.value(msg.value)(msg.sender);
    }
    
    /**
     * Allow sender to claim their refund to a Campaign by it's address.'
     * Calls the refund() function in the Campaign contract.
     */
    function refund(address _campaignAddress) external {
        Campaign deployedCampaign = Campaign(_campaignAddress);
        isDeployedByHub(deployedCampaign.campaignHub());
        deployedCampaign.refund(msg.sender);
    }
    
    /**
     * Allow the beneficiary to claim the fund of a Campaign by it's address.'
     * Calls the payOut() function in the Campaign contract.
     */
    function payOut(address _campaignAddress) external {
        Campaign deployedCampaign = Campaign(_campaignAddress);
        isDeployedByHub(deployedCampaign.campaignHub());
        deployedCampaign.payOut(msg.sender);
    }
    
    // endregion Public Functions
    
    
    // region Get View Functions
    
    function isBeneficiary(address _campaignAddress) public view returns(bool) {
        Campaign deployedCampaign = Campaign(_campaignAddress);
        return msg.sender == deployedCampaign.beneficiary();
    }
    
    function getContributionToVault(address _campaignAddress) public view returns(uint256) {
        Campaign deployedCampaign = Campaign(_campaignAddress);
        return deployedCampaign.getContributionToVault(msg.sender);
    }
    
    function getTotalFund(address _campaignAddress) public view returns(uint256) {
        Campaign deployedCampaign = campaigns[campaignAddressToId[_campaignAddress]];
        return deployedCampaign.getCurrentMatchVault();
    }
    
    function isOpen(address _campaignAddress) public view returns(bool) {
        Campaign deployedCampaign = campaigns[campaignAddressToId[_campaignAddress]];
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
    
    /**
     * Validation that the campaign is deployed by this hub.
     */
    function isDeployedByHub(address _hubAddress) public view {
        require(_hubAddress == address(this));
    }
    
    // endregion Condition validation Functions
}