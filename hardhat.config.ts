require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
import '@nomiclabs/hardhat-waffle';
import 'hardhat-contract-sizer';
import 'solidity-coverage'
import dotenv from 'dotenv';
dotenv.config();

const privateKey = process.env.PRIVATE_KEY;
const ALCHEMY_KEY = process.env.ALCHEMY_KEY;

module.exports = {
  solidity: {
    version: '0.8.7',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    goerli: {
      url: "https://goerli.infura.io/v3/0e42c582d71b4ba5a8750f688fce07da",
      accounts: [privateKey],
      gas: 'auto',
      timeout: 100000
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      accounts: [privateKey],
      gas: 'auto',
      timeout: 100000
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
};