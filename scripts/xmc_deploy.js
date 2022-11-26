// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat')

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  await hre.run('compile');

  let provider = ethers.provider;
  let signer = provider.getSigner();

  let my_address = await signer.getAddress();
  console.log(my_address);
 
  const XMC = await hre.ethers.getContractFactory('XMCToken')
  const xmc = await XMC.deploy()
  await xmc.deployed()
  // 0x3179e7dAe2ef85f5Ea135df9817ec9290Bbc9F32 v1
  console.log('xmc deployed to:', xmc.address)

  // await hre.run("verify:verify", {
  //   address: exchange.address,
  //   constructorArguments: [
  //       busd,
  //       zfuel,
  //       wallet
  //     ],
  //   }
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
