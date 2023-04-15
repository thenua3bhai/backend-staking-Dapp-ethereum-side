const { ethers } = require("hardhat");

const networkConfig = {
  default: {
    name: "hardhat",
  },
  31337: {
    name: "localhost",
  },
  5: {
    name: "goerli",

    erc20NTRO: "0x02D3d30bdEf23F087dE497645176C2C9171951Db",
  },
  11155111: {
    name: "sepolia",

    erc20NTRO: "0x6060Ed3A25e9d6aD09DfCc53E25191078E1caceA",
  },
  1: {
    name: "mainnet",
  },
};

const developmentChains = ["hardhat", "localhost"];
const VERIFICATION_BLOCK_CONFIRMATIONS = 6; //so that surely verified on etherscan until we will wait
const frontEndContractsFile = "../staking-frontend-next/constants/contractAddresses.json";
const frontEndAbiFile = "../staking-frontend-next/constants/abi.json";

const frontEndERC20ContractAddressesFile = "../staking-frontend-next/constants/erc20ContractAddresses.json";

module.exports = {
  networkConfig,
  developmentChains,
  VERIFICATION_BLOCK_CONFIRMATIONS,
  frontEndContractsFile,
  frontEndAbiFile,
  frontEndERC20ContractAddressesFile,
};
