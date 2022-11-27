# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```



# 交互

## 合约解释
1. 质押合约：XMCLPStake.sol，此合约是可升级合约，不可直接部署使用
2. 代理合约：XMCProxy.sol
3. 用于测试的代币合约：
   a. XMC代币：XMCToken.sol
   b. XMC-USDT-LP 代币 LPToken.sol

## 合约部署
1. 质押合约部署是UUPS 代理模式的可升级合约，部署参考 script/deploy.js 部署脚本
2. 测试代币合约可以直接部署

## 合约交互
###  质押LP 
1. 参考脚本 script/stake_deposit.js 脚本
2. 首先用户授权质押合约LP的权限
    ///////
    let approve_tx = await lp.approve(proxy_address, ethers.constants.MaxUint256);
  	await approve_tx.wait(); 
  	///////
3. 输入数量，调用质押合约
    ///////
    let amount = ethers.utils.parseEther("100");
  	let deposit_tx = await staking.depositLP(amount);
  	await deposit_tx.wait();
  	///////
4. 注意：首次质押不触发分红，从第二次开始

### 查询会员分红收益(2%)
1. 通过质押合约查询
2. 调用质押合约方法 withdrawableBonusOf(address)
  /////////
  // let info = await staking.withdrawableBonusOf(my_address);
  // console.log(ethers.utils.formatEther(info));
  ////////
3. 注意：这个方法仅查询质押LP的会员地址的分红数量

### 查询团长被动收益(1%)
1. 通过质押合约方法查询
2. 调用质押合约方法 withdrawableTeamBonusOf(address)
  /////////
  // let info = await staking.withdrawableTeamBonusOf(my_address);
  // console.log(ethers.utils.formatEther(info));
  ////////
3. 注意: 这个方法仅查询团长地址的分红数量
4. 注意: 如果没有团长，默认则认定管理员为团长

### 会员提取收益
1. 通过质押合约方法查询
2. 调用质押方法 claim()
  /////////
  // let claim_tx = await staking.claim();
  // await claim_tx.wait(); 
  /////////
3. 如果没有分红则会报错

### 团长提取收益
1. 通过质押合约方法查询
2. 调用质押方法 teamClaim()
  /////////
  // let claim_tx = await staking.teamClaim();
  // await claim_tx.wait(); 
  /////////
3. 如果没有分红则会报错


### 会员解除质押
1. 通过质押合约方法查询
2. 调用质押方法 withdrawLP()
  ///////
  // let withdraw_tx = await staking.withdrawLP();
  // await withdraw_tx.wait();
  /////////

### 查询质押中的会员总人数
1. 通过质押合约方法查询
2. 调用质押方法 getNumberOfStaked()
  ///////
  // let number = await staking.getNumberOfStaked();
  // console.log(number)
  /////////

### 查询领取收益的团长人数
1. 通过质押合约方法查询
2. 调用质押方法 getNumberOfLeader()
  ///////
  // let number = await staking.getNumberOfLeader();
  // console.log(number)
  /////////



 ## 测试
 ### 网络
 Goerli

 ### 合约地址
LP_TEST=0xd3daE7759Ae147969075f01AAd17a80cFf3c42F2
XMC_TEST=0x9a539cfF7a03640A07656e2c912C03Fc7Bef3157
STAKE_TEST=0x2E6760a23d98e2303a0cF7868fDa70305e4f33D4

 















