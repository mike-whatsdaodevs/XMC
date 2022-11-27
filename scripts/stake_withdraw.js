const { ethers, run } = require('hardhat')
require('dotenv').config({ path: '.env' })

async function main() {
  await run('compile')

  let provider = ethers.provider;
  let signer = provider.getSigner();

  let my_address = await signer.getAddress();
  console.log(my_address);

  let lp_address = process.env.LP_TEST;
  let proxy_address = process.env.PROXY_TEST;
  let xmc_address = process.env.XMC_TEST;
  let pool_address = process.env.POOL_TEST;
  let team_address = process.env.TEAM_TEST;

  const staking = await ethers.getContractAt('XMCLPStake', proxy_address, signer)
  const pool = await ethers.getContractAt('Pool', pool_address, signer)
  const team = await ethers.getContractAt('Pool', team_address, signer)
  const xmc = await ethers.getContractAt('XMCToken', xmc_address, signer)


  // let approve_tx = await pool.approve(proxy_address, ethers.constants.MaxUint256);
  // await approve_tx.wait();
  // return;

  // let amount = ethers.utils.parseEther("100");
  // let deposit_tx = await staking.depositLP(amount);
  // await deposit_tx.wait();

  // console.log("tx hash is", deposit_tx.hash);


  // let lpWithdrawableDividend = await pool.withdrawableDividendOf(my_address);
  // console.log("lpWithdrawableDividend is", lpWithdrawableDividend);
  // return;

  // let lp_pool = await staking.lpPool();

  // console.log(lp_pool);
  // return;

  // let team_pool = await staking.teamPool();
  // console.log("teamPool is", team_pool);
  // return;
  // let rewardToken = await team.rewardToken();
  // console.log("rewardToken is", rewardToken);

  // let totalSupply = await team.totalSupply();
  // console.log("totalSupply is", totalSupply);

  // let teamWithdrawableDividend = await team.withdrawableDividendOf(my_address);
  // console.log("teamWithdrawableDividend is", teamWithdrawableDividend);

  
  // return;

  // let pool_info = await pool.getAccount(my_address);
  // console.log(pool_info);

  // return;
  // let withdrawableDividendOf = await pool.withdrawableDividendOf(my_address);
  // console.log(withdrawableDividendOf);

  // let balance = await xmc.balanceOf(pool_address);
  // console.log("balance is",balance);
  // return;


  // let withdrawDividend_tx = await pool.withdrawDividend();
  // await withdrawDividend_tx.wait();
  // return;

  // let process_tx = await pool.processAccount(my_address, false);
  // await process_tx.wait();
  // console.log(process_tx.hash);
  // return;
 
  // let info = await staking.withdrawableDividendOf(my_address);
  // console.log(ethers.utils.formatEther(info));

  // return;

  let claim_tx = await staking.claim();
  await claim_tx.wait();
  console.log(claim_tx.hash);
  return;


  let withdraw_tx = await staking.withdrawLP();
  await withdraw_tx.wait();

  console.log("withdraw_tx hash is", withdraw_tx.hash);

 

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
