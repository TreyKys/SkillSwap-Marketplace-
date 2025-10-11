const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying contracts...");

  // Get the signer (account) that will deploy the contracts
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Escrow.sol
  const Escrow = await ethers.getContractFactory("Escrow", deployer);
  const escrow = await Escrow.deploy();
  await escrow.deployTransaction.wait();
  console.log(`✅ Escrow contract deployed to: ${escrow.address}`);

  // Deploy AssetToken.sol
  const AssetToken = await ethers.getContractFactory("AssetToken", deployer);
  const assetToken = await AssetToken.deploy();
  await assetToken.deployTransaction.wait();
  console.log(`✅ AssetToken contract deployed to: ${assetToken.address}`);

  console.log("\nDeployment complete! 🚀");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
