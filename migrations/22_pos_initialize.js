/**
 *  Init used packages
 */

const fs = require("fs");
const HDWalletProvider = require("@truffle/hdwallet-provider");
const _ = require("lodash");
const Web3 = require("web3");

/**
 * Init compiled contracts artifacts
 */
const InZToken = artifacts.require("InZToken");
const InZPos = artifacts.require("InZPos");

async function initialize({ inzPosInstance }) {
  await inzPosInstance.initialize();
}

/**
 * Export migration scenario
 * @param {deployer} deployer
 */
module.exports = async function (deployer) {
  // Log deployer address
  // console.log("*** Deployer Address: ", deployer);

  // Load address from .env file
  require("dotenv").config();

  // NOTE: load env
  const INZ_POS_ADDRESS = process.env.INZ_POS_ADDRESS;

  const ACC1_KEY = process.env.ACC1_KEY;
  const ACC2_KEY = process.env.ACC2_KEY;

  const RPC = "https://polygon-mumbai-bor.publicnode.com";

  const provider = new HDWalletProvider({
    privateKeys: [ACC1_KEY, ACC2_KEY],
    url: RPC,
  });

  const accountAddresses = provider.getAddresses();

  InZToken.setProvider(provider);
  InZPos.setProvider(provider);

  const inzPosInstance = await InZPos.at(INZ_POS_ADDRESS);

  await initialize({
    inzPosInstance,
  });
};
