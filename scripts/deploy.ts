import hre, { ethers, network } from 'hardhat';
import fs from 'fs';

import { verify, writeAddr } from './util';
// import { HouseBusiness, HouseBusinessToken, HouseStaking, MainCleanContract, ThirdParty } from '../typechain/pulse';

const addressFile = './contract_addresses/address.md';

const isTestNetwork = (name: string): name is 'goerli' | 'mumbai' => {
  return name === 'goerli' || name === 'mumbai';
}

async function main() {
  if (!isTestNetwork(network.name)) {
    console.log('main net')
    return;
  }
  console.log('Starting deployments');
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  const tokenAddress = '0xd0d178ed60436d0d1762ac58484eea154946edcd'; 

  const tokenFactory = await ethers.getContractFactory('HouseBusinessToken');
  const House = (await tokenFactory.deploy()) as HouseBusinessToken;
  await House.deployed();
  // const House = tokenFactory.attach(tokenAddress) as HouseBusinessToken;
  console.log('This is the token address: ', House.address);

  const HouseNFTFactory = await ethers.getContractFactory('HouseBusiness');
  const HouseNFT = (await HouseNFTFactory.deploy(House.address)) as HouseBusiness;
  await HouseNFT.deployed();
  console.log('This is the House NFT address: ', HouseNFT.address);

  const CContractFactory = await ethers.getContractFactory('MainCleanContract');
  const CContract = (await CContractFactory.deploy(HouseNFT.address)) as MainCleanContract;
  await CContract.deployed();
  console.log('This is the CContract address: ', CContract.address);

  const StakingFactory = await ethers.getContractFactory('HouseStaking');
  const StakingContract = (await StakingFactory.deploy(HouseNFT.address, House.address)) as HouseStaking;
  await StakingContract.deployed();
  console.log('This is the Staking contract address: ', StakingContract.address);

  const ThirdPartyFactory = await ethers.getContractFactory("ThirdParty");
  const ThirdPartyContract = (await ThirdPartyFactory.deploy()) as ThirdParty;
  await ThirdPartyContract.deployed();
  console.log('This is the third party address; ', ThirdPartyContract.address);

  let tx = await HouseNFT.connect(deployer).setCContractAddress(CContract.address);
  await tx.wait();

  tx = await HouseNFT.connect(deployer).setStakingContractAddress(StakingContract.address);
  await tx.wait();

  tx = await House.connect(deployer).transfer(StakingContract.address, ethers.utils.parseEther('100000'));
  await tx.wait();

  if (fs.existsSync(addressFile)) {
    fs.rmSync(addressFile);
  }

  fs.appendFileSync(addressFile, 'This file contains the latest test deployment addresses in the Goerli network<br/>');
  writeAddr(addressFile, network.name, House.address, 'ERC-20');
  writeAddr(addressFile, network.name, HouseNFT.address, 'HouseNFT');
  writeAddr(addressFile, network.name, CContract.address, 'CleanContract');

  console.log('Deployments done, waiting for etherscan verifications');

  // Wait for the contracts to be propagated inside Etherscan
  await new Promise((f) => setTimeout(f, 60000));

  await verify(HouseNFT.address, [House.address]);
  await verify(CContract.address, [HouseNFT.addesrs]);
  await verify(StakingContract.address, [HouseNFT.address, House.address]);

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
