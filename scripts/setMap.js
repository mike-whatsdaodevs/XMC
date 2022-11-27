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


  let leaders = [
    "0xbec9536B52d7977AD2bE0842Db0F74a79c40F010",
  ];

  let members = [
    "0xcCbF3c7eEB794e1275E6891B07E52eA4223F28BC",
  ]


  let changeTeamMap_tx = await staking.changeTeamMap(
    "0xbec9536B52d7977AD2bE0842Db0F74a79c40F010",
    "0xcCbF3c7eEB794e1275E6891B07E52eA4223F28BC"
  );
  await changeTeamMap_tx.wait();

  console.log(changeTeamMap_tx.hash);

  // let set_tx = await staking.batchSetTeamMap(leaders, members);
  // await set_tx.wait();
  // console.log("set_tx hash is", set_tx.hash);

 

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
