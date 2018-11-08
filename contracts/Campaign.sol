pragma solidity ^0.4.4;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Campaign {
    using SafeMath for uint256;

    struct Properties {
        string title;
        uint deadline;
        uint8 matchRate;
        address creator;
    }

    struct Contribution {
        uint amount;
        bool isMatchVault;
        address contributor;
    }

    address public campaignHub;

    mapping(address => uint) public contributors; // Map contributor address to his total contribution amount
    mapping(address => uint) public contributorToVault; // Map contributor address to his contribution to the match vault
    mapping(uint => Contribution) public contributions;

    uint public totalFunding;
    uint public totalMatchVault;
    uint public currentMatchVault;
    uint public contributionsCount;
    uint public contributorsCount;

    Properties public properties;

    event LogContributionReceived(address campaignAddress, address contributor, uint amount);
    event LogContributionVaultReceived(address campaignAddress, address contributor, uint amount);
    event LogPayoutInitiated(address campaignAddress, address owner, uint totalPayout);
    event LogRefundIssued(address campaignAddress, address contributor, uint refundAmount);

    event LogFailure(string message);

    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

    modifier onlyWhenClosed {
        require(hasClosed());
        _;
    }

    constructor (string _title, uint _deadline, uint8 _matchRate, address _creator) public {

        // Check to see the deadline is in the future
        if (block.timestamp >= _deadline) {
            emit LogFailure("Campaign deadline must be greater than the current block");
            revert();
        }

        // Check to see the match method is valid
        if (_matchRate >= 0) {
            emit LogFailure("Match method must be greater than 0");
            revert();
        }

        // Check to see that a creator (payout) address is valid
        if (_creator == 0) {
            emit LogFailure("Campaign must include a valid creator address");
            revert();
        }

        campaignHub = msg.sender;

        // initialize properties struct
        properties = Properties({
            title : _title,
            deadline : _deadline,
            matchRate : _matchRate,
            creator : _creator
            });

        totalFunding = 0;
        totalMatchVault = 0;
        currentMatchVault = 0;
        contributionsCount = 0;
        contributorsCount = 0;
    }

    /**
    * Campaign values are indexed in return value:
    * [0] -> Campaign.properties.title
    * [1] -> Campaign.properties.deadline
    * [2] -> Campaign.properties.matchRate
    * [3] -> Campaign.properties.creator
    * [4] -> Campaign.totalFunding
    * [5] -> Campaign.totalMatchVault
    * [6] -> Campaign.currentMatchVault
    * [7] -> Campaign.contributionsCount
    * [8] -> Campaign.contributorsCount
    * [9] -> Campaign.campaignHub
    * [10] -> Campaign (address)
    */
    function getCampaign() external view returns (string, uint, uint8, address, uint, uint, uint, uint, uint, address, address) {
        return (properties.title,
        properties.deadline,
        properties.matchRate,
        properties.creator,
        totalFunding,
        totalMatchVault,
        currentMatchVault,
        contributionsCount,
        contributorsCount,
        campaignHub,
        address(this));
    }

    /**
    * Retrieve indiviual contribution information
    * [0] -> Contribution.amount
    * [1] -> Contribution.isMatchVault
    * [2] -> Contribution.contributor
    */
    function getContribution(uint _id) external view returns (uint, bool, address) {
        Contribution memory c = contributions[_id];
        return (c.amount, c.isMatchVault, c.contributor);
    }

    /**
    * This is the function called when the CampaignHub receives a contribution.
    * If the contribution was sent after the deadline of the campaign passed,
    * the function must return the value to the originator of the transaction.
    * [0] -> fund was successful
    */
    function fund(address _contributor, bool _isMatchVault) external onlyWhileOpen payable returns (bool successful) {
        _preValidateContribution(_contributor, msg.value);

        // determine if this is a new contributor
        uint prevContributionBalance = contributors[_contributor];

        // Update fund
        if (_isMatchVault) {
            require(properties.matchRate > 0);
            totalMatchVault += msg.value;
            currentMatchVault += msg.value;
        } else {
            require(currentMatchVault > msg.value * properties.matchRate);
            totalFunding += msg.value * (1 + properties.matchRate);
            currentMatchVault -= msg.value * properties.matchRate;
        }
        contributionsCount++;

        // Add contribution to contributions map
        Contribution memory c = contributions[contributionsCount];
        c.contributor = _contributor;
        c.amount = msg.value;
        c.isMatchVault = _isMatchVault;

        // Update contributor's balance in match vault
        if (_isMatchVault) {
            contributorToVault[_contributor] += msg.value;
        }

        // Check if contributor is new and if so increase count
        if (prevContributionBalance == 0) {
            contributorsCount++;
        }

        emit LogContributionReceived(this, _contributor, msg.value);

        return true;
    }

    /*
    * Transfer fund to campaign creator
    */
    function payout() external onlyWhenClosed payable returns (bool successful) {
        require(msg.sender == properties.creator);

        uint amount = totalFunding;

        // prevent re-entrancy attack
        totalFunding = 0;

        if (properties.creator.send(amount)) {
            return true;
        } else {
            totalFunding = amount;
            return false;
        }

        return true;
    }

    /**
    * If the deadline is passed, allow match maker contributors to withdraw their contributions.
    * [0] -> refund was successful
    */
    function refund() external payable returns (bool successful) {

        require(hasClosed());
        require(contributorToVault[msg.sender] > 0);

        uint amount = (contributorToVault[msg.sender] / totalMatchVault) * currentMatchVault;

        //prevent re-entrancy attack
        contributorToVault[msg.sender] = 0;

        if (msg.sender.send(amount)) {
            emit LogRefundIssued(address(this), msg.sender, amount);
            return true;
        } else {
            contributors[msg.sender] = amount;
            emit LogFailure("Refund did not send successfully");
            return false;
        }
        return true;
    }

    /**
     * @dev Validation of an incoming contribution.
     * @param _contributor Address performing the campaign contribution
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidateContribution(address _contributor, uint _weiAmount) internal {
        require(_contributor != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @return true if the campaign is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp <= properties.deadline;
    }

    /**
     * @dev Checks whether the period in which the campaign is open has already elapsed.
     * @return Whether campaign period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return block.timestamp > properties.deadline;
    }

    function kill() public {
        require(msg.sender == properties.creator);
        selfdestruct(campaignHub);
    }

    /**
    * Don't allow Ether to be sent blindly to this contract
    */
    function() public {
        revert();
    }
}