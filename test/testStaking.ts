import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';
import { expect } from 'chai';
import { PLSP, PotLottery } from '../typechain/pulse';
import '@nomiclabs/hardhat-waffle';

describe('Staking feature', async () => {
  let PLSP: PLSP;
  let PotLottery: PotLottery;
  let user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress, deployer: SignerWithAddress;

  const logPLSPStatus = async () => {
    let airdropPool = ethers.utils.formatEther(await PotLottery.airdropPool());
    let lotteryPool = ethers.utils.formatEther(await PotLottery.lotteryPool());
    let burnPool = ethers.utils.formatEther(await PotLottery.burnPool());

    console.log(`Airdrop Pool: ${airdropPool}, Lottery Pool: ${lotteryPool}, Burn Pool: ${burnPool}`);

    let user1Staking = ethers.utils.formatEther(await PLSP.userStakingAmount(user1.address));
    let user2Staking = ethers.utils.formatEther(await PLSP.userStakingAmount(user2.address));
    let user3Staking = ethers.utils.formatEther(await PLSP.userStakingAmount(user3.address));
    console.log(`Staking User1: ${user1Staking}, User2: ${user2Staking}, User3: ${user3Staking}`);

    let user1Balance = ethers.utils.formatEther(await PLSP.balanceOf(user1.address));
    let user2Balance = ethers.utils.formatEther(await PLSP.balanceOf(user2.address));
    let user3Balance = ethers.utils.formatEther(await PLSP.balanceOf(user3.address));
    let potBalance = ethers.utils.formatEther(await PLSP.balanceOf(PotLottery.address));
    console.log(`Balance User1: ${user1Balance}, User2: ${user2Balance}, User3: ${user3Balance}, Pot: ${potBalance}`);
  };

  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    user1 = accounts[0];
    user2 = accounts[1];
    user3 = accounts[3];
    deployer = accounts[2];

    const PLSPFactory = await ethers.getContractFactory('PLSP');
    const PotLotteryV2Factory = await ethers.getContractFactory('PotLottery');

    PLSP = (await PLSPFactory.connect(deployer).deploy('PLSP', 'PLSP')) as PLSP;
    PotLottery = (await upgrades.deployProxy(PotLotteryV2Factory, [deployer.address], {
      initializer: 'initialize',
      kind: 'transparent',
    })) as PotLottery;

    // Set addresses for each other
    await PLSP.connect(deployer).setPotContractAddress(PotLottery.address);
    await PotLottery.connect(deployer).setPLSPAddress(PLSP.address);

    // // Sends tokens to initial users
    await PLSP.connect(deployer).transfer(user1.address, ethers.utils.parseEther('1'));
    await PLSP.connect(deployer).transfer(user2.address, ethers.utils.parseEther('1'));
    await PLSP.connect(user1).transfer(user3.address, ethers.utils.parseEther('0.3'));
  });

  it('should fail before the airdrop time', async () => {
    console.log(await PLSP.isAirdropping());
    await expect(PotLottery.connect(deployer).airdropAccumulatedPLSP()).to.be.reverted;
  });
  it('should fail before the lottery time', async () => {
    await expect(PotLottery.connect(deployer).lotteryAccumulatedPLSP()).to.be.reverted;
  });

  it('should fail before staking time', async () => {
    await PotLottery.connect(deployer).setStakingMinimum(ethers.utils.parseEther('0.1'));
    await PLSP.connect(user1).stakePLSP(ethers.utils.parseEther('0.5'));
    await expect(PLSP.connect(user1).unStakePLSP(0)).to.be.reverted;
  });

  it('should check staking pool', async () => {
    await PotLottery.connect(deployer).setStakingMinimum(ethers.utils.parseEther('0.1'));
    await PLSP.connect(user1).stakePLSP(ethers.utils.parseEther('0.5'));
    await expect(PLSP.connect(user1).transfer(user2.address, ethers.utils.parseEther('0.6'))).to.be.reverted;
  });

  // it('can unstake after staking time', async () => {
  //   // Sets Staking
  //   await PotLottery.connect(deployer).setStakingMinimum(ethers.utils.parseEther('0.1'));
  //   await PotLottery.connect(deployer).setMinimumStakingTime(5);
  //   await PLSP.connect(user1).stakePLSP(ethers.utils.parseEther('0.5'));
  //   await PLSP.connect(user1).stakePLSP(ethers.utils.parseEther('0.1'));

  //   await new Promise((f) => setTimeout(f, 8000));
  //   await PLSP.connect(user1).unStakePLSP(0);
  //   const stakingBalance = await PLSP.userStakingAmount(user1.address);

  //   await expect(PLSP.userStakingAmount(user1.address)).to.equal(ethers.utils.parseEther('0.1'));
  // });

  // it('should airdrop correctly - with airdrop minimum', async () => {
  //   // Sets Staking
  //   await PotLottery.connect(deployer).setStakingMinimum(ethers.utils.parseEther('0.1'));
  //   await PLSP.connect(user1).stakePLSP(ethers.utils.parseEther('0.5'));
  //   await PLSP.connect(user2).stakePLSP(ethers.utils.parseEther('0.3'));

  //   // Sets Accumulated Fees
  //   await PLSP.connect(deployer).transfer(PotLottery.address, ethers.utils.parseEther('1'));
  //   await PotLottery.connect(deployer).setAdminFeeToken('PLSP', ethers.utils.parseEther('1'));
  //   await PotLottery.connect(deployer).setAirdropInterval(6);

  //   await logPLSPStatus();

  //   console.log('waiting for the airdrop....');
  //   await new Promise((f) => setTimeout(f, 8000));

  //   console.log('performing the first airdrop....');
  //   await PotLottery.connect(deployer).airdropAccumulatedPLSP();

  //   await logPLSPStatus();
  // });

  it('lottery choose winner', async () => {
    // Sets Staking
    await PotLottery.connect(deployer).setStakingMinimum(ethers.utils.parseEther('0.1'));
    await PLSP.connect(user1).stakePLSP(ethers.utils.parseEther('0.7'));
    await PLSP.connect(user2).stakePLSP(ethers.utils.parseEther('0.1'));

    await PLSP.connect(deployer).transfer(PotLottery.address, ethers.utils.parseEther('1'));
    await PotLottery.connect(deployer).setAdminFeeToken('PLSP', ethers.utils.parseEther('1'));
    await PotLottery.connect(deployer).setLotteryInterval(1);

    await logPLSPStatus();
    console.log('waiting for the lottery....');
    await new Promise((f) => setTimeout(f, 2000));

    const balance = ethers.utils.formatEther(await PLSP.balanceOf(user3.address));
    const tx = await PotLottery.connect(deployer).lotteryAccumulatedPLSP();
    const res = await tx.wait();
    const event = res.events.find((event) => event.event === 'LotterySuccess');
    const [winner] = event.args;

    await logPLSPStatus();

    console.log(balance, winner);
  });
});
