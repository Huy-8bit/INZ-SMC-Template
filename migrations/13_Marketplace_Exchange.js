const BN = require("bn.js");
const fs = require("fs");
const Exchange = artifacts.require("Exchange");

const debug = "true";

const ZERO = new BN(0);
const ONE = new BN(1);
const TWO = new BN(2);
const THREE = new BN(3);

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

function wf(name, address) {
  fs.appendFileSync("address.txt", name + "=" + address);
  fs.appendFileSync("address.txt", "\r\n");
}

module.exports = async function (deployer, network, accounts) {
  let account = deployer.options?.from || accounts[0];
  if (network == "test" || network == "development") return;

  require("dotenv").config();

  const { OWNER, SIGNER } = process.env;

  console.log("DEPLOYER : ", account);

  /**
   *  @dev Deploy new instant of Exchange smart contract
   */
  await deployer.deploy(Exchange);
  let ExchangeInst = await Exchange.deployed();
  wf("Exchange", ExchangeInst.address);

  /**
   *  @dev Grant the Admin Role for owner
   */
  await ExchangeInst.grantRole(await ExchangeInst.DEFAULT_ADMIN_ROLE(), OWNER);

  /**
   *  @dev Grant the signer role for signer
   */
  await ExchangeInst.grantRole(await ExchangeInst.SIGNER_ROLE(), SIGNER);

  /**
   * @dev Revoke the role ADMIN of the deployer
   */
  await ExchangeInst.renounceRole(
    await ExchangeInst.DEFAULT_ADMIN_ROLE(),
    account
  );
  console.log("Exchange =", ExchangeInst.address);
};
