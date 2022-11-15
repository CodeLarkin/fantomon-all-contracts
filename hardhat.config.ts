import "@nomiclabs/hardhat-truffle5";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers"

import { task } from "hardhat/config";

import 'hardhat-contract-sizer';
import "hardhat-gas-reporter";

import "solidity-coverage";


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
//task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
//  const accounts = await hre.ethers.getSigners();
//
//  for (const account of accounts) {
//    console.log(account.address);
//  }
//});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  networks: {
    hardhat: {
      accounts: {
        count: 613,
        accountsBalance: "1000000000000000000000000"  // 10000 ETH
      }
    },
    fantomtestnet: {
      url: "https://rpc.testnet.fantom.network",
      accounts: [process.env.PRIVK],
      chainId: 4002,
      live: false,
      saveDeployments: true,
      gasMultiplier: 2,
    },
    fantommainnet: {
      //url: "https://rpc.ankr.com/fantom",
      url: "https://rpc.ftm.tools",
      accounts: [process.env.PRIVK],
      chainId: 250,
      live: false,
      saveDeployments: true,
      gasMultiplier: 3,
    },
    fantomankr: {
      url: "https://rpc.ankr.com/fantom",
      accounts: [process.env.PRIVK],
      chainId: 250,
      live: false,
      saveDeployments: true,
      gasMultiplier: 2,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.7",
        settings: {
          optimizer: {
          enabled: true,
            runs: 40000,
          },
        },
      },
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 40000,
          },
        },
      },
      {
        version: "0.8.13",
        settings: {
          optimizer: {
            enabled: true,
            runs: 40000,
          },
        },
      },
    ],
    overrides: {
      "contracts/FantomonTrainer.sol": {
        version: "0.8.7",
        settings: {
          optimizer: {
          enabled: true,
            runs: 20000,
          },
        },
      },
      "contracts/FantomonGraphics.sol": {
        version: "0.8.9",
        settings: {
          optimizer: {
          enabled: true,
            runs: 1,
          },
        },
      },
      "contracts/FantomonRoyaltiesPerMon.sol": {
        version: "0.8.9",
        settings: {
          optimizer: {
          enabled: true,
            runs: 1,
          },
        },
      },
    }
  },
  mocha: {
    timeout: 20000000000
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: (process.env.HARDHAT_REPORTS) ? true : false,
    strict: false,
  },
  gasReporter: {
    currency: 'FTM',
    gasPrice: 300,
    enabled: (process.env.HARDHAT_REPORTS) ? true : false,
  }
};
