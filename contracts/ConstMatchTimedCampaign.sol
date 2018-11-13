pragma solidity ^0.4.4;

import './SafeMath.sol';

contract ConstMatchTimedCampaign {
    using SafeMath for uint256;

    address public creator;

    string title;
    uint256 openingTime;
    uint256 closingTime;
    uint256 matchConst;

    uint256 totalFund;
    uint256 totalMatchVault;
    uint256 currentMatchVault;

    mapping(address => uint256) contributorToVault;

    event DirectContributionReceived(address campaign, address contributor, uint256 amount);
    event VaultContributionReceived(address campaign, address contributor, uint256 amount);
    event RefundSent(address campaign, address constructor, uint256 amount);


    // region Contrstruction and Public Functions

    constructor(string _title, uint256 _openingTime, uint256 _closingTime, uint256 _matchConst) public {
        require(_openingTime < _closingTime);
        creator = msg.sender;
        title = _title;
        openingTime = now.add(_openingTime);
        closingTime = now.add(_closingTime);
        matchConst = _matchConst;
    }

    /**
    * This is the function called to fund directly.
    */
    function fundDirect() payable external {
        require(isOpen());
        _preValidateContribution(msg.sender, msg.value);
        require(isEnoughFundInVault());
        totalFund += msg.value + matchConst;
        currentMatchVault -= matchConst;
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
    * Transfer fund to campaign creator
    */
    function payOut() external {
        require(isCreator());
        require(!isOpen());

        uint256 amount = totalFund;
        // prevent re-entrancy
        totalFund = 0;

        creator.transfer(amount);
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

    function getMatchConst() public view returns (uint256) {
        return matchConst;
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
     * Check whether there is enough fund in vault to match.
     * Should call this function before fundDirectly() to avoid unnecessary gas fee.
     */
    function isEnoughFundInVault() public view returns (bool) {
        return currentMatchVault >= matchConst;
    }

    /**
     * Validation of an incoming contribution.
     */
    function _preValidateContribution(address _contributor, uint256 _amount) internal pure {
        require(_contributor != address(0));
        require(_amount != 0);
    }

    /**
     * Revert to inital state if called by any account other than the creator.
     */
    function isCreator() public view returns(bool) {
        return msg.sender == creator;
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