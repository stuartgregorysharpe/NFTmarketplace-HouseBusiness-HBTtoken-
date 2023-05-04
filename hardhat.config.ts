require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
import '@nomiclabs/hardhat-waffle';
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import dotenv from 'dotenv';
dotenv.config();

// infuraId
const infuraId = process.env.INFURA_ID;
// const privateKey = process.env.PRIVATE_KEY;
const privateKey = "f2ec77cb1556b5b1212c6cf5c086177316ae8c719507a4706dfc3f06ca543b6b"
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
  defaultNetwork: 'bnbt',
  networks: {
    bsc: {
      url: 'https://bsc-dataseed2.binance.org',
      accounts: [privateKey],
      network_id: 56,
      gasLimit: 55000000000000,
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true,
    },
    bnbt: {
      // url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      url: `https://newest-falling-layer.bsc-testnet.quiknode.pro/97d2bad70da983db0c16ab40774d882c718e4e10`,
      // accounts: ['03930ff96c737456580946926663695f8d8cdae90617a3bf371a7c59a2d06079'],
      accounts: [privateKey],
      network_id: 97,
      gasPrice: 30000000000,
      gas: 5000000,
      confirmations: 2,
      timeoutBlocks: 30,
      skipDryRun: true,
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/axk_8yCPO5yxqRKEY3XVVVd8U43dEKPg`,
      accounts: [privateKey],
      network_id: 5,
      confirmations: 5,
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
    // apiKey: '2DDSXSQDUBTEQ8NJVRBB3XRAPMVTWP4U1T',
    apiKey: 'D7VHJ687GHKP79N8I2FGTE6NX9Q8P1F8YI',
  },
};
