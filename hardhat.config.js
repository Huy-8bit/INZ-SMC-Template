/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("chai");
require("ethers");
require("ethereum-waffle");
require("dotenv").config();
// require("dotenv").config({ path: ".env-test" });

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const REAL_ACCOUNTS = process.env.REAL_ACCOUNTS;
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    zetachain: {
      url: "https://zetachain-athens-evm.blockpi.network/v1/rpc/public",
      accounts: [REAL_ACCOUNTS],
    },
    sepolia: {
      url: "https://ethereum-sepolia.blockpi.network/v1/rpc/public",
      accounts: [REAL_ACCOUNTS],
    },
    polygon_testnet: {
      url: "https://polygon-mumbai-bor.publicnode.com",
      accounts: [REAL_ACCOUNTS],
    },
    scroll: {
      url: "https://alpha-rpc.scroll.io/l2",
      accounts: [REAL_ACCOUNTS],
    },
    base_goerli: {
      url: "https://goerli.base.org",
      accounts: [REAL_ACCOUNTS],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.5.7",
      },
      {
        version: "0.8.18",
      },
      {
        version: "0.6.12",
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
