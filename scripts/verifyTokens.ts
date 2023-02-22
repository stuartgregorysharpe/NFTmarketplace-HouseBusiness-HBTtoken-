import { ethers, network } from 'hardhat';
import fs from 'fs';
import hre from 'hardhat';
import { verify, writeAddr } from './util';

async function main() {
  const HexAddress = '0x2BEd9CE54334825245dA8fD4d145312f1749BC8D';
  const MaxiAddress = '0x130173163D9B89A14A8c04dDaE758cb6ef6C3B98';
  const BUSDAddress = '0x4608Ea31fA832ce7DCF56d78b5434b49830E91B1';

  await verify(HexAddress, ['Hex', 'Hex']);
  await verify(MaxiAddress, ['MAXI', 'MAXI']);
  await verify(BUSDAddress, ['BUSD', 'BUSD']);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
