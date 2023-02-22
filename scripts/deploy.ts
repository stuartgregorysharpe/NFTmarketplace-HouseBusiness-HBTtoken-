import hre, { ethers, network } from 'hardhat';
import fs from 'fs';

import { verify, writeAddr } from './util';
import { HouseBusiness, MainCleanContract } from '../typechain/pulse';

const addressFile = './contract_addresses/address.md';
async function main() {
  console.log('Starting deployments');
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  const tokenAddress = '0x509Ee0d083DdF8AC028f2a56731412edD63223B9'; // usdt

  const HouseNFTFactory = await ethers.getContractFactory('HouseBusiness');
  const HouseNFT = (await HouseNFTFactory.deploy(tokenAddress)) as HouseBusiness;
  await HouseNFT.deployed();
  console.log('This is the House NFT address: ', HouseNFT.address);

  const CContractFactory = await ethers.getContractFactory('MainCleanContract');
  const CContract = (await CContractFactory.deploy(HouseNFT.address)) as MainCleanContract;
  await CContract.deployed();
  console.log('This is the CContract address: ', CContract.address);

  let tx = await HouseNFT.connect(deployer).setCContractAddress(CContract.address);
  await tx.wait();

  if (fs.existsSync(addressFile)) {
    fs.rmSync(addressFile);
  }

  fs.appendFileSync(addressFile, 'This file contains the latest test deployment addresses in the Goerli network<br/>');
  writeAddr(addressFile, network.name, tokenAddress, 'ERC-20');
  writeAddr(addressFile, network.name, HouseNFT.address, 'HouseNFT');
  writeAddr(addressFile, network.name, CContract.address, 'CleanContract');

  console.log('Deployments done, waiting for etherscan verifications');

  // Wait for the contracts to be propagated inside Etherscan
  await new Promise((f) => setTimeout(f, 60000));

  await verify(HouseNFT.address, [tokenAddress]);
  await verify(CContract.address, [HouseNFT.address]);

  console.log('All done');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
