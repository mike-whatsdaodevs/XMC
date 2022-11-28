// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

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

  let lp_test = process.env.LP_TEST;
  let xmc_test = process.env.XMC_TEST;

  
  const Lib = await hre.ethers.getContractFactory('IterableMapping')
  let lib = await Lib.deploy()
  await lib.deployed()
  console.log("lib is", lib.address);

  let lib_address = lib.address;


  const XMCLPStake = await hre.ethers.getContractFactory(
    'XMCLPStake', {
      libraries: {
        IterableMapping: lib_address,
      }
    }
  )
  const staking = await XMCLPStake.deploy()
  await staking.deployed()


  let implement = staking.address;
  console.log("staking implement address is:", implement)

  const StakeObj = await hre.ethers.getContractAt('XMCLPStake', implement, signer)
  const initialize_data = await StakeObj.populateTransaction.initialize(
    xmc_test,
    lp_test
  )
  console.log("initialize data is",initialize_data)

  const XMCProxy = await hre.ethers.getContractFactory('XMCProxy')
  let proxy = await XMCProxy.deploy(implement, initialize_data.data)
  await proxy.deployed()
  console.log("proxy is", proxy.address);

  // await hre.run("verify:verify", {
  //   address: proxy.address,
  //   contract: "contracts/BTCZProxy.sol:BTCZProxy",
  //   constructorArguments: [
  //       zstaking_address,
  //       hre.ethers.utils.arrayify(initialize_data)
  //     ],
  //   }
  // );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
