const { network } = require("hardhat");

//Or we can write it 5e8
const MAX_TOKEN_SUPPLY = "500000000"; //It is cap for max.supply token have,not initial ,initial is 5 Lacs and specified in contract
const REWARD = "20";

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts(); //In Local dev chain,hardhat automatically gives it first account,these accounts are not specified in config file
  const chainId = network.config.chainId;
  // If we are on a local development network, we need to deploy mocks! no need to deploy mocks on real testnet
  if (chainId == 31337) {
    log("Local network detected! Deploying mocks...");
    await deploy("NeutronToken", {
      from: deployer,
      log: true,
      args: [MAX_TOKEN_SUPPLY, REWARD],
    });

    log("Mocks Deployed!");
    log("----------------------------------------------------------");
  }
};
module.exports.tags = ["all", "mocks"];
