pragma solidity ^0.4.4;

import './SafeMath.sol';

contract RateMatchTimedCampaign {
    using SafeMath for uint256;

    address public beneficiary;

    string title;
    uint256 openingTime;
    uint256 closingTime;
    uint256 matchRate;

    uint256 totalFund;
    uint256 totalMatchVault;
    uint256 currentMatchVault;

    mapping(address => uint256) contributorToVault;

    event DirectContributionReceived(address campaign, address contributor, uint256 amount);
    event VaultContributionReceived(address campaign, address contributor, uint256 amount);
    event RefundSent(address campaign, address constructor, uint256 amount);


    // region Contrstruction and Public Functions

    constructor(string _title,
                uint256 _openingTime,
                uint256 _closingTime,
                uint256 _matchRate,
                address _beneficiary
                ) public {
        require(_openingTime < _closingTime);
        title = _title;
        openingTime = now.add(_openingTime);
        closingTime = now.add(_closingTime);
        matchRate = _matchRate;
        beneficiary = _beneficiary;
    }

    /**
    * This is the function called to fund directly.
    */
    function fundDirect() payable external {
        require(isOpen());
        _preValidateContribution(msg.sender, msg.value);
        require(isEnoughFundInVault(msg.value));
        uint256 matchAmout = msg.value * matchRate;
        totalFund += msg.value + matchAmout;
        currentMatchVault -= matchAmout;
        emit DirectContributionReceived(address(this), msg.sender, msg.value);
    }

    /**
    * This is the function called to put fund into the match vault.
    */
    function fundVault() payable external {
        require(isOpen());
        _preValidateContribution(msg.sender, msg.value);
        totalMatchVault += msg.value;
        currentMatchVault += msg.value;
        contributorToVault[msg.sender] += msg.value;
        emit VaultContributionReceived(address(this), msg.sender, msg.value);
    }

    /**
    * Transfer fund to the beneficiary of this campaign
    */
    function payOut() external {
        require(isBeneficiary());
        require(!isOpen());

        uint256 amount = totalFund;
        // prevent re-entrancy
        totalFund = 0;

        beneficiary.transfer(amount);
    }

    /**
     * If the deadline is passed, allow contributors to withdraw their vault contributions.
     */
    function refund() external {
        require(!isOpen());
        require(contributorToVault[msg.sender] > 0);

        uint256 amount = (uint256) (contributorToVault[msg.sender] / totalMatchVault) * currentMatchVault;

        // prevent re-entrancy
        contributorToVault[msg.sender] = 0;

        msg.sender.transfer(amount);

        emit RefundSent(address(this), msg.sender, amount);
    }

    // endregion Contrstruction and Public Functions


    // region Get View Functions

    function getTitle() public view returns (string) {
        return title;
    }

    function getMatchRate() public view returns (uint256) {
        return matchRate;
    }

    function getTotalFund() public view returns (uint256) {
        return totalFund;
    }

    function getMatchFund() public view returns (uint256) {
        return totalMatchVault;
    }

    function getCurrentMatchVault() public view returns (uint256) {
        return currentMatchVault;
    }

    function getVaultContribution() public view returns (uint256) {
        return contributorToVault[msg.sender];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // endregion Get View Functions


    // region Condition validation Functions

    /**
     * Check whether there is enough fund in vault to match with amount.
     * Should call this function before fundDirectly() to avoid unnecessary gas fee.
     */
    function isEnoughFundInVault(uint256 _amount) public view returns (bool) {
        return currentMatchVault >= _amount.mul(1 + matchRate);
    }

    /**
     * Validation of an incoming contribution.
     */
    function _preValidateContribution(address _contributor, uint256 _amount) internal pure {
        require(_contributor != address(0));
        require(_amount != 0);
    }

    /**
     * Revert to inital state if called by any account other than the beneficiary.
     */
    function isBeneficiary() public view returns(bool) {
        return msg.sender == beneficiary;
    }

    /**
     * Return true if the campaign is open, false otherwise.
     * Should call this function before fund() to avoid unnecessary gas fee.
     */
    function isOpen() public view returns (bool) {
        return now >= openingTime && now <= closingTime;
    }

    // endregion Condition validation Functions
}