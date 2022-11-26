// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Pool.sol";


contract XMCLPStake is Ownable {

    Pool public lpPool;
    Pool public teamPool;
    using SafeMath for uint256;

    IERC20 public rewardToken; //XMC
    IERC20 public LP;

    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 2;
    uint256 public teamFee = 1;

    address public marketingWallet = 0x4893dF6F4857f59e90aa6C59E4e2a3168719ccBF;
    mapping(address => uint256) public stakeInfo;


    event UpdatePool(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

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
    	lpPool = new Pool(address(rewardToken));
        
    }

    receive() external payable {}

    function updatePool(address newAddress) public onlyOwner {
        require(newAddress != address(lpPool), "BabyDogePaid: The dividend tracker already has that address");

        Pool newPool = Pool(newAddress);

        require(newPool.owner() == address(this), "BabyDogePaid: The new dividend tracker must be owned by the BabyDogePaid token contract");

        emit UpdatePool(newAddress, address(lpPool));

        lpPool = newPool;
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

    function getClaimWait() external view returns(uint256) {
        return lpPool.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return lpPool.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return lpPool.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return lpPool.balanceOf(account);
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

    function claim() external {
		lpPool.processAccount(msg.sender, false);
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
            rewardToken.transfer(address(lpPool), teamFeeAmount);
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
        lpPool.safeMint(msg.sender, amount);

        shareFees();
        uint256 dividends = IERC20(rewardToken).balanceOf(address(lpPool));
        lpPool.distributeDividends(dividends);

        stakeInfo[msg.sender] = stakeInfo[msg.sender].add(amount);
    }

    /// @dev withdraw lp from contract, need approve first
    function withdrawLP() external {
        uint256 amount = lpPool.balanceOf(msg.sender);
        require(stakeInfo[msg.sender] == amount, "E: amount error");

        lpPool.transferFrom(msg.sender, address(this), amount);
        lpPool.safeBurn(address(this), amount);
        LP.transfer(msg.sender, amount);

        shareFees();
        uint256 dividends = IERC20(rewardToken).balanceOf(address(lpPool));
        lpPool.distributeDividends(dividends);

        stakeInfo[msg.sender] = 0;

        lpPool.processAccount(msg.sender, false);
    }


    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return lpPool.getNumberOfTokenHolders();
    }


}
