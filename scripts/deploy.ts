import hre, { ethers, network } from 'hardhat';
import fs from 'fs';

import { verify, writeAddr } from './util';

const addressFile = './contract_addresses/address.md';

const isTestNetwork = (name: string): name is 'goerli' | 'mumbai' => {
  return name === 'goerli' || name === 'mumbai';
}

const defaultHistoryType = [
  {
    hLabel: 'Construction',
    connectContract: false,
    imgNeed: false,
    brandNeed: false,
    descNeed: false,
    brandTypeNeed: false,
    yearNeed: false,
    checkMark: false,
    value: 0
  },
  {
    hLabel: 'Floorplan',
    connectContract: true,
    imgNeed: true,
    brandNeed: false,
    descNeed: true,
    brandTypeNeed: false,
    yearNeed: true,
    checkMark: false,
    value: 0
  },
  {
    hLabel: 'Pictures',
    connectContract: true,
    imgNeed: true,
    brandNeed: true,
    descNeed: true,
    brandTypeNeed: true,
    yearNeed: false,
    checkMark: false,
    value: 0
  },
  {
    hLabel: 'Blueprint',
    connectContract: true,
    imgNeed: true,
    brandNeed: true,
    descNeed: false,
    brandTypeNeed: true,
    yearNeed: true,
    checkMark: false,
    value: 0
  },
  {
    hLabel: 'Solarpanels',
    connectContract: true,
    imgNeed: true,
    brandNeed: true,
    descNeed: true,
    brandTypeNeed: true,
    yearNeed: true,
    checkMark: false,
    value: 0
  },
  {
    hLabel: 'Airconditioning',
    connectContract: false,
    imgNeed: true,
    brandNeed: true,
    descNeed: true,
    brandTypeNeed: true,
    yearNeed: true,
    checkMark: false,
    value: 0
  }, {
    hLabel: 'Sonneboiler',
    connectContract: true,
    imgNeed: true,
    brandNeed: true,
    descNeed: true,
    brandTypeNeed: false,
    yearNeed: true,
    checkMark: false,
    value: 0
  },
  {
    hLabel: 'Housepainter',
    connectContract: true,
    imgNeed: true,
    brandNeed: false,
    descNeed: true,
    brandTypeNeed: true,
    yearNeed: true,
    checkMark: false,
    value: 0
  }
]

async function main() {
  if (!isTestNetwork(network.name)) {
    console.log('main net')
    return;
  }
  console.log('Starting deployments');
 
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  const tokenAddress = '0xa8C19667794191A730B3983eB3a8087CfF2b788e';
  const houseBusiness = '0xEFfdCe06C3cC709f46cbaC457a335aa62AA4dA0F';

  const tokenFactory = await ethers.getContractFactory('HouseBusinessToken');
  // const House = (await tokenFactory.deploy()) as HouseBusinessToken;
  // await House.deployed();
  const House = tokenFactory.attach(tokenAddress) as HouseBusinessToken;
  console.log('This is the token address: ', House.address);

  const HouseNFTFactory = await ethers.getContractFactory('HouseBusiness');
  const HouseNFT = (await HouseNFTFactory.deploy(House.address)) as HouseBusiness;
  await HouseNFT.deployed();
  // const HouseNFT = HouseNFTFactory.attach(houseBusiness) as HouseBusiness;
  console.log('This is the House NFT address: ', HouseNFT.address);

  const HouseDocFactory = await ethers.getContractFactory('HouseDoc');
  const HouseDoc = (await HouseDocFactory.deploy(HouseNFT.address)) as HouseDoc;
  await HouseDoc.deployed();
  console.log('This is the HouseDoc address: ', HouseDoc.address);

  const StakingFactory = await ethers.getContractFactory('HouseStaking');
  const StakingContract = (await StakingFactory.deploy(HouseNFT.address, House.address)) as HouseStaking;
  await StakingContract.deployed();
  console.log('This is the Staking contract address: ', StakingContract.address);

  const ThirdPartyFactory = await ethers.getContractFactory("ThirdParty");
  const ThirdPartyContract = (await ThirdPartyFactory.deploy()) as ThirdParty;
  await ThirdPartyContract.deployed();
  console.log('This is the third party address; ', ThirdPartyContract.address);

  const operatorFactory = await ethers.getContractFactory('Operator');
  const Operator = (await operatorFactory.deploy(House.address)) as Operator;
  await Operator.deployed();
  console.log('This is the Operator address: ', Operator.address);

  let tx = await HouseNFT.connect(deployer).setHouseDocContractAddress(HouseDoc.address);
  await tx.wait();

  tx = await HouseNFT.connect(deployer).setStakingContractAddress(StakingContract.address);
  await tx.wait();

  tx = await HouseNFT.connect(deployer).setOperatorAddress(Operator.address);
  await tx.wait();

  tx = await House.connect(deployer).transfer(StakingContract.address, ethers.utils.parseEther('100000'));
  await tx.wait();

  tx = await HouseDoc.connect(deployer).setOperatorAddress(Operator.address);
  await tx.wait();

  tx = await StakingContract.connect(deployer).setOperatorAddress(Operator.address);
  await tx.wait();

  tx = await Operator.connect(deployer).authorizeContracts([
    House.address, HouseNFT.address, HouseDoc.address, StakingContract.address
  ]);
  await tx.wait();
  for (var i = 0; i < defaultHistoryType.length; i++) {
    tx = await HouseNFT.connect(deployer).addHistoryType(
      i,
      defaultHistoryType[i].hLabel,
      defaultHistoryType[i].connectContract,
      defaultHistoryType[i].imgNeed,
      defaultHistoryType[i].brandNeed,
      defaultHistoryType[i].descNeed,
      defaultHistoryType[i].brandTypeNeed,
      defaultHistoryType[i].yearNeed,
      defaultHistoryType[i].checkMark,
      0,
      true
    )
    await tx.wait();
  }

  if (fs.existsSync(addressFile)) {
    fs.rmSync(addressFile);
  }

  fs.appendFileSync(addressFile, 'This file contains the latest test deployment addresses in the Goerli network<br/>');
  writeAddr(addressFile, network.name, House.address, 'ERC-20');
  writeAddr(addressFile, network.name, HouseNFT.address, 'HouseNFT');
  writeAddr(addressFile, network.name, HouseDoc.address, 'HouseDocu');

  console.log('Deployments done, waiting for etherscan verifications');

  // Wait for the contracts to be propagated inside Etherscan
  await new Promise((f) => setTimeout(f, 60000));

  await verify(HouseNFT.address, [House.address]);
  await verify(HouseDoc.address, [HouseNFT.address]);
  await verify(StakingContract.address, [HouseNFT.address, House.address]);
  await verify(Operator.address, [House.address]);

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
