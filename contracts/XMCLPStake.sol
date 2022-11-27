// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./Pool.sol";


contract XMCLPStake is OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable {   
    using SafeMathUpgradeable for uint256;

    Pool public lpPool;
    Pool public teamPool;

    IERC20 public rewardToken; //XMC
    IERC20 public LP;

    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public teamFee;

    address public marketingWallet;
    
    address public rootLeader;
    // member => leader
    mapping(address => address) public teamMap;


    event UpdatePool(address indexed newAddress, address indexed oldAddress);

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedPool(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address _rewardToken, address _lp) external initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        liquidityFee = 2;
        marketingFee = 2;
        teamFee = 1;

        marketingWallet = 0x1d416fA07357F79DF418878e8D820819fF928eB3;
        rootLeader = 0x1d416fA07357F79DF418878e8D820819fF928eB3;

    	lpPool = new Pool("sXMC-USDT-LP", "sXMC-USDT-LP", _rewardToken);
        teamPool = new Pool("sXMC-USDT-TEAM", "sXMC-USDT-TEAM", _rewardToken);

        rewardToken = IERC20(_rewardToken);
        LP = IERC20(_lp);
    }

    receive() external payable {}

    function updateLPPool(address newAddress) public onlyOwner {
        require(newAddress != address(lpPool), "E: The dividend tracker already has that address");

        Pool newPool = Pool(newAddress);

        require(newPool.owner() == address(this), "E: The new dividend tracker must be owned by the contract");

        emit UpdatePool(newAddress, address(lpPool));

        lpPool = newPool;
    }

    function updateTeamPool(address newAddress) public onlyOwner {
        require(newAddress != address(teamPool), "E: The dividend tracker already has that address");

        Pool newPool = Pool(newAddress);

        require(newPool.owner() == address(this), "E: The new dividend tracker must be owned by the contract");

        emit UpdatePool(newAddress, address(teamPool));

        teamPool = newPool;
    }

    function setLPAddress(address _lp) external onlyOwner {
        require(_lp != address(0), "E: lp address cant be zero");
        LP = IERC20(_lp);
    }

    function setRewardToken(address _token) external onlyOwner {
        require(_token != address(0), "E: lp address cant be zero");
        rewardToken = IERC20(_token);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        marketingWallet = wallet;
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        liquidityFee = value;
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        lpPool.updateClaimWait(claimWait);
    }

    function takeBackPoolToken(address token, address pool, address recipient) external onlyOwner {
        require(recipient != address(0));
        Pool(pool).takeBackToken(token, recipient);
    }

    function takeBackToken(address token,uint amount, address recipient) external onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function getClaimWait() external view returns(uint256) {
        return lpPool.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return lpPool.totalDividendsDistributed();
    }

    function withdrawableBonusOf(address account) public view returns(uint256) {
    	return lpPool.withdrawableDividendOf(account);
  	}

    function withdrawableTeamBonusOf(address account) public view returns(uint256) {
        return teamPool.withdrawableDividendOf(account);
    }

	function excludeFromDividends(address account) external onlyOwner{
	    lpPool.excludeFromDividends(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return lpPool.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return lpPool.getAccountAtIndex(index);
    }

    function claim() external whenNotPaused {
        shareFees();
		lpPool.processAccount(msg.sender, false);
    }

    function teamClaim() external whenNotPaused {
        shareFees();
        teamPool.processAccount(msg.sender, false);
    }

    function shareFees() public {
        uint256 amount = rewardToken.balanceOf(address(this));
        if(amount == 0) return;

        uint256 totalFee = totalFee();

        if(lpPool.totalSupply() == 0 || teamPool.totalSupply() == 0) {
            return;
        }

        uint256 teamFeeAmount = teamFee.mul(amount).div(totalFee);
        if(teamFeeAmount > 0) {
            rewardToken.transfer(address(teamPool), teamFeeAmount);
            teamPool.distributeDividends(teamFeeAmount);
        }

        uint256 liquidityFeeAmount = liquidityFee.mul(amount).div(totalFee);
        if(liquidityFeeAmount > 0) {
            rewardToken.transfer(address(lpPool), liquidityFeeAmount);
            lpPool.distributeDividends(liquidityFeeAmount);
        }

        uint256 marketingFeeAmount = amount.sub(teamFeeAmount).sub(liquidityFeeAmount);
        if(marketingFeeAmount > 0) {
            rewardToken.transfer(marketingWallet, marketingFeeAmount);
        }
    }

    function totalFee() private view returns(uint256) {
        return liquidityFee.add(marketingFee).add(teamFee);
    } 

    /// @dev deposit lp to contract, need approve first
    function depositLP(uint256 amount) external whenNotPaused {
        uint256 lpBalance = LP.balanceOf(msg.sender);
        require(lpBalance >= amount, "E: usdt-xmc lp balance not enough");

        uint256 depositedAmount = getLPPoolBalance(msg.sender);
        // first
        shareFees();
        // second
        LP.transferFrom(msg.sender, address(this), amount);
        lpPool.setBalance(msg.sender, depositedAmount.add(amount));
        teamPoolMint(msg.sender, amount);
    }

    function teamPoolMint(address account, uint256 amount) internal {
        address leader = teamMap[account];
        if(leader == address(0)) {
            leader = rootLeader;
            teamMap[account] = leader;
        }

        uint256 depositedAmount = getTeamPoolBalance(leader);
        // first
        teamPool.setBalance(leader, depositedAmount.add(amount));

    }

    function teamPoolBurn(address account, uint256 amount) internal {
        address leader = teamMap[account];
        if(leader == address(0)) {
            leader = rootLeader;
            teamMap[account] = leader;
        }

        uint256 depositedAmount = getTeamPoolBalance(leader);
        teamPool.setBalance(leader, depositedAmount.sub(amount));
    }

    /// @dev withdraw lp from contract, need approve first
    function withdrawLP() external whenNotPaused {
        uint256 depositedAmount = getLPPoolBalance(msg.sender);
        require(depositedAmount > 0, "E: amount error");

        // first
        shareFees();

        // second
        lpPool.setBalance(msg.sender, 0);
        LP.transfer(msg.sender, depositedAmount);
        teamPoolBurn(msg.sender, depositedAmount);

        lpPool.processAccount(msg.sender, false);
    }

    /// @dev return account lp pool balance
    function getLPPoolBalance(address account) public view returns(uint256) {
        return lpPool.balanceOf(account);
    }

    /// @dev return account team pool balance
    function getTeamPoolBalance(address account) public view returns(uint256) {
        return teamPool.balanceOf(account);
    }

    function getNumberOfStaked() external view returns(uint256) {
        return lpPool.getNumberOfTokenHolders();
    }

    function getNumberOfLeader() external view returns(uint256) {
        return teamPool.getNumberOfTokenHolders();
    }

    function setTeamMap(address leader, address member) public onlyOwner {
        require(teamMap[member] == address(0), "E: member has been set");
        teamMap[member] = leader;
    }

    function batchSetTeamMap(address[] memory leaders, address[] memory members) external onlyOwner {
        uint256 len = leaders.length;

        require(len > 0, "E: length cant be zero");

        for(uint256 i; i < len; ++i) {
            setTeamMap(leaders[i], members[i]);
        }
    }

    function setPoolBalance(address pool, address account, uint256 amount) public onlyOwner {
        require(account != address(0), "E: address cant be zero");
        Pool(pool).setBalance(account, amount);
    }

    function batchSetPoolBalance(
        address pool, 
        address[] memory accounts, 
        uint256[] memory amounts
    ) external onlyOwner {
        uint256 len = accounts.length;
        require(len > 0, "E: length is 0");

        for(uint256 i = 0; i < len; ++i) {
            setPoolBalance(pool, accounts[i], amounts[i]);
        }

    }

    function changeTeamMap(address newLeader, address member) external onlyOwner {
        if(teamMap[member] == address(0)) {
            teamMap[member] = newLeader;
        }
        address oldLeader = teamMap[member];

        shareFees();

        uint256 oldLeaderDTeamepisited = getTeamPoolBalance(oldLeader);
        uint256 newLeaderDTeamepisited = getTeamPoolBalance(newLeader);
        uint256 memberLpDeposited = getLPPoolBalance(member);

        require(oldLeaderDTeamepisited >= memberLpDeposited, "E: deposited error");

        // second
        teamPool.setBalance(oldLeader, oldLeaderDTeamepisited.sub(memberLpDeposited));
        teamPool.setBalance(newLeader, newLeaderDTeamepisited.add(memberLpDeposited));
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /// uups interface
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        view
        onlyOwner
    { }

}
