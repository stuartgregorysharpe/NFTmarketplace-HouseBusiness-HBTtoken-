require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
import '@nomiclabs/hardhat-waffle';
// import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import 'solidity-coverage'
import dotenv from 'dotenv';
dotenv.config();

const privateKey = process.env.PRIVATE_KEY;
const ALCHEMY_KEY = process.env.ALCHEMY_KEY;
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
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
  // defaultNetwork: 'goerli',
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
  // mocha: {
  //   timeout: 400000,
  // },
  // gasReporter: {
  //   enabled: false,
  //   currency: 'USD',
  // },
  // contractSizer: {
  //   runOnCompile: false,
  // },
  etherscan: {
    apiKey: process.env.ETHER_KEY
  },
};
