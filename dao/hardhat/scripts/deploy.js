const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {

  const DGITokenAddress = "0xAF6d8e44FA696f919fDbbA53890E7032Aa7BcE1e";
  const DogerPupsNFTAddress = "0xDa06F33f87D44e21e0BDdB1209e3b70aa9515d69";

  const DogerDAO = await hre.ethers.getContractFactory("DogerDAO");
  const dogerDAO = await DogerDAO.deploy(DogerPupsNFTAddress, DGITokenAddress, 5);

  await dogerDAO.deployed();

  console.log("Doger DAO deployed to: "+ dogerDAO.address); //0x491798272DBe4074E663665Ca868Bb4C47a2E514

  //transfer the ownership
  const DogerNFT = await ethers.getContractAt("DogerPupsNFT", DogerPupsNFTAddress);
  const transferOwnertx = await DogerNFT.transferOwnership(dogerDAO.address);
  await transferOwnertx.wait();
  const ownerIs = await DogerNFT.owner();

  console.log("owner transferred");
  console.log("owner address: ", ownerIs);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});