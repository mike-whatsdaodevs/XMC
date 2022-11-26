// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./DividendTracker.sol";


contract XMCLPStake is Ownable {

    DividendTracker public dividendTracker;
    using SafeMath for uint256;

    IERC20 public rewardToken; //XMC
    IERC20 public LP;

    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 2;
    uint256 public teamFee = 1;

    address public marketingWallet = 0x4893dF6F4857f59e90aa6C59E4e2a3168719ccBF;
    mapping(address => uint256) public stakeInfo;


    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() {
    	dividendTracker = new DividendTracker(address(rewardToken));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BabyDogePaid: The dividend tracker already has that address");

        DividendTracker newDividendTracker = DividendTracker(newAddress);

        require(newDividendTracker.owner() == address(this), "BabyDogePaid: The new dividend tracker must be owned by the BabyDogePaid token contract");

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function setLPAddress(address _lp) external onlyOwner {
        require(_lp != address(0), "E: lp address cant be zero");
        LP = IERC20(_lp);
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
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
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
        return dividendTracker.getAccount(account);
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
    	return dividendTracker.getAccountAtIndex(index);
    }

    function claim() external {
		dividendTracker.processAccount(msg.sender, false);
    }

    function shareFees() public {
        uint256 amount = rewardToken.balanceOf(address(this));
        if(amount == 0) return;

        uint256 totalFee = totalFee();

        uint256 teamFeeAmount = teamFee.mul(amount).div(totalFee);
        if(teamFeeAmount > 0) {
            rewardToken.transfer(address(this), teamFeeAmount);
        }

        uint256 liquidityFeeAmount = liquidityFee.mul(amount).div(totalFee);
        if(liquidityFeeAmount > 0) {
            rewardToken.transfer(address(dividendTracker), teamFeeAmount);
        }

        uint256 marketingFee = amount.sub(teamFeeAmount).sub(liquidityFeeAmount);
        if(marketingFee > 0) {
            rewardToken.transfer(marketingWallet, marketingFee);
        }
    }

    function totalFee() private view returns(uint256) {
        return liquidityFee.add(marketingFee).add(teamFee);
    } 

    /// @dev deposit lp to contract, need approve first
    function depositLP(uint256 amount) external {
        uint256 lpBalance = LP.balanceOf(msg.sender);
        require(lpBalance >= amount, "E: usdt-xmc lp balance not enough");

        LP.transferFrom(msg.sender, address(this), amount);

        shareFees();

        dividendTracker.safeMint(msg.sender, amount);

        uint256 dividends = IERC20(rewardToken).balanceOf(address(dividendTracker));
        dividendTracker.distributeDividends(dividends);

        stakeInfo[msg.sender] = stakeInfo[msg.sender].add(amount);
    }

    function withdrawLP() external {
        uint256 amount = dividendTracker.balanceOf(msg.sender);
        require(stakeInfo[msg.sender] == amount, "E: amount error");

        dividendTracker.transferFrom(msg.sender, address(this), amount);

        shareFees();

        dividendTracker.safeBurn(address(this), amount);

        uint256 dividends = IERC20(rewardToken).balanceOf(address(dividendTracker));
        dividendTracker.distributeDividends(dividends);

        stakeInfo[msg.sender] = 0;

        dividendTracker.processAccount(msg.sender, false);
    }


    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }


}
