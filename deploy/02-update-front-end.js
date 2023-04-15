const { frontEndContractsFile, frontEndAbiFile, frontEndERC20ContractAddressesFile, networkConfig } = require("../helper-hardhat-config");
const fs = require("fs");
const { network } = require("hardhat");

//from here we will update addresses of deployed contracts  and abi of smart contract on frontend,so that front can interact with them.
module.exports = async () => {
  if (process.env.UPDATE_FRONT_END) {
    console.log("Writing to front end...");
    await updateContractAddresses();
    await updateAbi();
    await updateERC20ContractAddresses();
    console.log("Front end written!");
  }
};

async function updateAbi() {
  const stakingAndReward = await ethers.getContract("StakingAndReward");
  fs.writeFileSync(frontEndAbiFile, stakingAndReward.interface.format(ethers.utils.FormatTypes.json));
}

async function updateContractAddresses() {
  const stakingAndReward = await ethers.getContract("StakingAndReward");
  const contractAd = stakingAndReward.address;
  const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"));
  const chainId = network.config.chainId.toString();

  //searching key in json object
  if (chainId in contractAddresses) {
    if (!contractAddresses[chainId].includes(contractAd)) {
      contractAddresses[chainId].push(contractAd);
    } else {
      let len = contractAddresses[chainId].length; //checking length of array
      if (len > 1) {
        let i = contractAddresses[chainId].indexOf(contractAd);
        let temp = contractAddresses[chainId][i];
        contractAddresses[chainId][i] = contractAddresses[chainId][len - 1];
        contractAddresses[chainId][len - 1] = temp;
      }
    }
  } else {
    contractAddresses[chainId] = [contractAd];
  }
  fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses));
}

async function updateERC20ContractAddresses() {
  const contractAddresses = JSON.parse(fs.readFileSync(frontEndERC20ContractAddressesFile, "utf8"));
  const chainId = network.config.chainId.toString();
  if (chainId === "31337") {
    const neutronToken = await ethers.getContract("NeutronToken");
    if (chainId in contractAddresses) {
      if (!contractAddresses[chainId].includes(neutronToken.address)) {
        contractAddresses[chainId].push(neutronToken.address);
      } else {
        let len = contractAddresses[chainId].length;
        if (len > 1) {
          let i = contractAddresses[chainId].indexOf(neutronToken.address);
          let temp = contractAddresses[chainId][i];
          contractAddresses[chainId][i] = contractAddresses[chainId][len - 1];
          contractAddresses[chainId][len - 1] = temp;
        }
      }
    } else {
      contractAddresses[chainId] = [neutronToken.address];
    }
  } else {
    //it is address of real token contract deployed on testnet/mainnet
    erc20NTROAddress = networkConfig[chainId]["erc20NTRO"];
    if (chainId in contractAddresses) {
      if (!contractAddresses[chainId].includes(erc20NTROAddress)) {
        contractAddresses[chainId].push(erc20NTROAddress);
      }
    } else {
      contractAddresses[chainId] = [erc20NTROAddress];
    }
  }
  fs.writeFileSync(frontEndERC20ContractAddressesFile, JSON.stringify(contractAddresses));
}
module.exports.tags = ["all", "frontend"];
