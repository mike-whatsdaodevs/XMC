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

  const staking = await ethers.getContractAt('XMCLPStake', proxy_address, signer)
  const lp = await ethers.getContractAt('LPToken', lp_address, signer)
  const xmc = await ethers.getContractAt('XMCToken', xmc_address, signer)


  let approve_tx = await lp.approve(proxy_address, ethers.constants.MaxUint256);
  await approve_tx.wait();

  let amount = ethers.utils.parseEther("100");
  let deposit_tx = await staking.depositLP(amount);
  await deposit_tx.wait();

  console.log("tx hash is", deposit_tx.hash);
  return;

  let lp_pool = await staking.lpPool();

  console.log(lp_pool);
  return;

  console.log(ethers.utils.formatEther(await xmc.balanceOf(lp_pool)));

  console.log(ethers.utils.formatEther(await staking.withdrawableDividendOf(my_address)));

  // console.log(await staking.lpPool());

  let claim_tx = await staking.claim();
  await claim_tx.wait();

  console.log("claim_tx hash is", claim_tx.hash);

 

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
