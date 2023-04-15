const { network, ethers } = require("hardhat"); //ethers from hardhat
const { networkConfig, developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config");
require("dotenv").config();
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId; //hardhat populate this from hardhat-config based on  whichever n/w we deploy using command-line,
  let erc20NTROMock, erc20NTROAddress;

  if (chainId == 31337) {
    erc20NTROMock = await ethers.getContract("NeutronToken"); //Gives latest deployed instance of this contract on hardhat n/w
    erc20NTROAddress = erc20NTROMock.address;
  } else {
    erc20NTROAddress = networkConfig[chainId]["erc20NTRO"]; //accessing data from  objects inside helper-hardhat-config.js
  }
  const waitBlockConfirmations = developmentChains.includes(network.name) ? 1 : VERIFICATION_BLOCK_CONFIRMATIONS;
  //so that surely verified on etherscan until we will wait

  log("----------------------------------------------------");
  const arguments = [erc20NTROAddress]; //args address based on ChainId
  const stakingAndReward = await deploy("StakingAndReward", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  });

  // Verify the deployment
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...");
    await verify(stakingAndReward.address, arguments);
  }

  const networkName = network.name == "hardhat" ? "localhost" : network.name;
  log(`Contract deployed to Network :${networkName} and Address: ${stakingAndReward.address}`);
  log("----------------------------------------------------");
};

module.exports.tags = ["all", "staking"];

//npx hardhat deploy --tags all OR staking
//to run this script
