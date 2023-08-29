  const fs = require("fs");
  const Exchange = artifacts.require("ExchangeUpgradeable");
  const ExchangeProxy = artifacts.require("ExchangeProxy");
  const StorageSlot = artifacts.require("StorageSlot");

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
    *  @dev Deploy new instant of Exchange
    */
    await deployer.deploy(Exchange);
    let iExchange = await Exchange.deployed();
    wf("Exchange", iExchange.address);

    /**
    *  @dev Deploy Exchange Proxy Libraries
    */
    await deployer.deploy(StorageSlot);
    var iStorageSlot = await StorageSlot.deployed();
    await deployer.link(iStorageSlot, ExchangeProxy);
    console.log("Link libraries sucess.");

    /**
    *  @dev Deploy Exchange Proxy
    */
    await deployer.deploy(ExchangeProxy);
    let iExchangeProxy = await ExchangeProxy.deployed();
    wf("ExchangeProxy", iExchangeProxy.address);

    /**
    * @dev Set implementation of the proxy to Exhchange
    */
    await iExchangeProxy.setImplementation(iExchange.address, { from: account });
    console.log("Set new implementation success.");

    /**
    * @dev Set Exchange to the proxy
    */
    iExchange = await Exchange.at(iExchangeProxy.address);

    await iExchange.initialize({ from: account });
    console.log("Initialize success.");

    /**
    *  @dev Grant the Admin Role for owner
    */
    await iExchange.grantRole(await iExchange.DEFAULT_ADMIN_ROLE(), OWNER);
    console.log("Grant admin role for owner success.");

    /**
    *  @dev Grant the signer role for signer
    */
    await iExchange.grantRole(await iExchange.SIGNER_ROLE(), SIGNER);
    console.log("Grant signer role for signer success.");

    /**
    * @dev Revoke the role ADMIN of the deployer
    */
    await iExchange.renounceRole(await iExchange.DEFAULT_ADMIN_ROLE(), account);
    console.log("Revoke admin role of deployer success.");
  };
