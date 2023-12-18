
const hre = require("hardhat");

async function main() {

  const baseUrl = "ipfs://QmYLWSQxc3MxAQiXvknud9ZEaqpq7ckyHhYPexwSDwm3cr/";
  const DGITokenAddress = "0xAF6d8e44FA696f919fDbbA53890E7032Aa7BcE1e";

  const DogerPupsNFT = await hre.ethers.getContractFactory("DogerPupsNFT");
  // const DogerPupsNFT = await hre.ethers.deployContract("DogerPupsNFT",baseUrl, DGITokenAddress);
  const DogerPups = await DogerPupsNFT.deploy(baseUrl, DGITokenAddress);

  await DogerPups.deployed();

  console.log(
    `DogerPups NFTs contract deployed to ${DogerPups.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
