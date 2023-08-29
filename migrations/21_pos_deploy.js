/**
 *  Init used packages
 */

const fs = require("fs");

/**
 * Init compiled contracts artifacts
 */
const InZToken = artifacts.require("InZToken");
const InZPos = artifacts.require("InZPos");

/**
 * Write address of deployed contracts to a file named 'address.txt' in root folder
 * @param {string} name
 * @param {string} address
 */
function wf(name, address) {
  fs.appendFileSync("address.txt", name + "=" + address);
  fs.appendFileSync("address.txt", "\r\n");
}

/**
 * Export migration scenario
 * @param {deployer} deployer
 */
module.exports = async function (deployer) {
  // Log deployer address
  console.log("*** Deployer Address: ", deployer.address);

  // Load address from .env file
  require("dotenv").config();

  //      0. Deploy payToken
  await deployer.deploy(InZToken);
  var iInZToken = await InZToken.deployed();
  console.log("InZToken", InZToken.address);
  wf("InZToken", iInZToken.address);

  await deployer.deploy(InZPos);
  var iInZPos = await InZPos.deployed();
  console.log("InZPos", InZPos.address);
  wf("InZPos", iInZPos.address);

  const inzPosInstance = await InZPos.at(iInZPos.address);
  inzPosInstance.initialize();
  console.log("Initialize InZPos Success");
};
