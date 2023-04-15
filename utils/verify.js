const { run } = require("hardhat");

const verify = async (contractAddress, args) => {
  console.log("Verifying contract...");
  try {
    //Hardhat run  doing the work for us we are giving just our key in config and deployed contract address to verify
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!");
    } else {
      console.log(e);
    }
  }
};

module.exports = {
  verify,
};
