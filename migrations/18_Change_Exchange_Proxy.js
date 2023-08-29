const fs = require("fs");
const Exchange = artifacts.require("ExchangeUpgradeable");
const ExchangeProxy = artifacts.require("ExchangeProxy");
const StorageSlot = artifacts.require("StorageSlot");

function wf(name, address) {
  fs.appendFileSync("address.txt", name + "=" + address);
  fs.appendFileSync("address.txt", "\r\n");
}

const settings = {
  deployNewExchange: true,
};

module.exports = async function (deployer, network, accounts) {
  let account = deployer.options?.from || accounts[0];
  if (network == "test" || network == "development") return;

  require("dotenv").config();

  const { OWNER, SIGNER } = process.env;

  console.log("DEPLOYER : ", account);

  if (settings.deployNewExchange) {
    await deployer.deploy(Exchange);
    var iExchange = await Exchange.deployed();
    wf("Exchange", iExchange.address);
  } else {
    var iExchange = process.env.Exchange;
  }

  let ExchangeProxyAddr = process.env.ExchangeProxy;
  var iExchangeProxy = await ExchangeProxy.at(ExchangeProxyAddr);

  /**
   * @dev Set implementation of the proxy to Exhchange
   */
  await iExchangeProxy.setImplementation(iExchange.address, { from: account });
  console.log("Set new implementation success.");
};
