pragma solidity ^0.4.4;

import './Campaign.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract CampaignHub {
    using SafeMath for uint256;

    address public owner;
    uint public numOfCampaigns;

    event LogNewCampaign(uint id, string title, uint deadline, uint8 matchRate, address addr, address creator);
    event LogContributionSent(address campaignAddress, address contributor, uint amount);

    event LogFailure(string message);

    Campaign[] public campaigns;

    mapping(uint => address) public campaignToOwner;
    mapping(address => uint) ownerCampaignCount;

    constructor () internal {
        owner = msg.sender;
        numOfCampaigns = 0;
    }

    /**
    * Create a new Campaign contract
    * [0] -> new Campaign contract address
    */
    function createCampaign(string _title, uint _deadline, uint8 _matchRate) external returns (Campaign campaignAddress) {

        if (block.timestamp >= _deadline) {
            emit LogFailure("Campaign deadline must be greater than the current block");
            revert();
        }

        Campaign cp = new Campaign(_title, _deadline, _matchRate, msg.sender);
        campaigns[numOfCampaigns] = cp;
        emit LogNewCampaign(numOfCampaigns, _title, _deadline, _matchRate, cp, msg.sender);
        numOfCampaigns++;
        return cp;
    }

    /**
    * Allow senders to contribute to a Campaign by it's address. Calls the fund() function in the Campaign
    * contract and passes on all value attached to this function call
    * [0] -> contribution was sent
    */
    function contribute(address _campaignAddress, bool _isMatchVault) external payable returns (bool successful) {

        // Check amount sent is greater than 0
        if (msg.value <= 0) {
            emit LogFailure("Contributions must be greater than 0 wei");
            revert();
        }

        Campaign deployedCampaign = Campaign(_campaignAddress);

        // Check that there is actually a Campaign contract at that address
        if (deployedCampaign.campaignHub() == address(0)) {
            emit LogFailure("Campaign contract not found at address");
            revert();
        }

        // Check that fund call was successful
        if (deployedCampaign.fund.value(msg.value)(msg.sender, _isMatchVault)) {
            emit LogContributionSent(_campaignAddress, msg.sender, msg.value);
            return true;
        } else {
            emit LogFailure("Contribution did not send successfully");
            return false;
        }
    }
}