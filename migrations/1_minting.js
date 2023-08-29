const console = require("console");
const fs = require("fs");

// command line run: truffle migrate --f 1 --to 1 --network base_goerli -reset --compile-none

var InzUSDT = artifacts.require("USDT");
var InterfaceFunction = artifacts.require("InterfaceFunction");
var InZCampaignFactory = artifacts.require("InZCampaignFactory");
var Configurations = artifacts.require("Configurations");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");
var InZTreasury = artifacts.require("InZTreasury");
var GatewayNFT = artifacts.require("GatewayNFT");

function wf(name, address) {
  fs.appendFileSync("address.txt", name + "=" + address);
  fs.appendFileSync("address.txt", "\r\n");
}

const deployments = {
  usdt: false,
  lib: false,
  factory: false,
  dapp: false,
  treasury: false,
  config: false,
  reconfig_config_to_factory: false,
  init_config_to_creator: false,
  init_config: false,
  init_config_treasury: false,
  gateway: false,
  gateway_authorize: true,
  create_new: true,
};

module.exports = async function (deployer, network, accounts) {
  let account = deployer.options?.from || accounts[0];
  console.log("deployer = ", account);
  require("dotenv").config();
  var _devWallet = process.env.DEV_WALLET;

  /**
   *      0.1.    Deploy USDT test for the platform payment
   */
  if (deployments.usdt) {
    await deployer.deploy(InzUSDT);
    var _iUSDT = await InzUSDT.deployed();
    wf("USDT", _iUSDT.address);
  } else {
    var _iUSDT = await InzUSDT.at(process.env.USDT);
  }

  /**
   *      0.2.    Deploy Interface Functions
   */
  if (deployments.lib) {
    await deployer.deploy(InterfaceFunction);
    var iInterfaceFunction = await InterfaceFunction.deployed();
    wf("InterfaceFunction", iInterfaceFunction.address);
  } else {
    var iInterfaceFunction = await InterfaceFunction.at(
      process.env.InterfaceFunction
    );
  }

  /**
   *      1.  Deploy Factory
   */
  if (deployments.factory) {
    // Link with interfaceFunctions
    await deployer.link(iInterfaceFunction, InZCampaignFactory);
    // Deloy new Factory
    await deployer.deploy(
      InZCampaignFactory,
      "0x0000000000000000000000000000000000000000"
    );
    var _factory = await InZCampaignFactory.deployed();
    wf("InZCampaignFactory", _factory.address);
  } else {
    var _factory = await InZCampaignFactory.at(process.env.InZCampaignFactory);
  }

  /**
   *      2.  Deploy Dapp Creator
   */
  if (deployments.dapp) {
    await deployer.deploy(DaapNFTCreator, _devWallet);
    var _creator = await DaapNFTCreator.deployed();
    wf("DaapNFTCreator", _creator.address);
  } else {
    var _creator = await DaapNFTCreator.at(process.env.DaapNFTCreator);
  }

  /**
   *      3.  Deploy InZTreasury
   */
  if (deployments.treasury) {
    await deployer.deploy(
      InZTreasury,
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000"
    );
    var _treasuryContract = await InZTreasury.deployed();
    wf("InZTreasury", _treasuryContract.address);
  } else {
    var _treasuryContract = await InZTreasury.at(process.env.InZTreasury);
  }

  /**
   *      4.  Deploy NftConfigurations
   */
  if (deployments.config) {
    await deployer.deploy(
      Configurations,
      _factory.address,
      _creator.address,
      _treasuryContract.address
    );
    var _nftConfig = await Configurations.deployed();
    wf("Configurations", _nftConfig.address);
  } else {
    var _nftConfig = await Configurations.at(process.env.Configurations);
  }

  /**
   *      5.  Re-config NftConfigurations to NftFactory
   */
  if (deployments.reconfig_config_to_factory) {
    console.log("reconfig_config_to_factory");
    await _factory.setConfiguration(_nftConfig.address);
    console.log("setConfiguration success");
  }

  /**
   *      6.  Initialize DappCreator
   */
  if (deployments.init_config_to_creator) {
    console.log("init_config_to_creator");
    await _creator.initialize(
      _nftConfig.address,
      _treasuryContract.address,
      "0x0000000000000000000000000000000000000000",
      process.env.PLATFORM_FEE_ADDRESS
    );
    console.log("initialize success");
  }

  /**
   *      7.  Initialize NftConfigurations
   */
  if (deployments.init_config) {
    console.log("init_config");
    await _nftConfig.initialize();
    console.log("initialize success");
  }

  /**
   *      8.  Initialize NftConfigurations
   */
  if (deployments.init_config_treasury) {
    console.log("init_config_treasury");
    await _treasuryContract.initialize();
    console.log("initialize success");
    await _treasuryContract.setNftConfiguration(_nftConfig.address);
    console.log("setNftConfiguration success");
    await _treasuryContract.setCreator(_creator.address);
    console.log("setCreator success");
  }

  /**
   *      9. Deploy GatewayNFT
   */
  if (deployments.gateway) {
    await deployer.deploy(
      GatewayNFT,
      process.env.WETH,
      process.env.OwnerGateway
    );
    var _gatewayNFT = await GatewayNFT.deployed();
    wf("GatewayNFT", _gatewayNFT.address);
  } else {
    var _gatewayNFT = await GatewayNFT.at(process.env.GatewayNFT);
  }

  if (deployments.gateway_authorize) {
    // await _creator.setNewGateway(_gatewayNFT.address);
    // await new Promise((r) => setTimeout(r, 15000));
    // console.log("set new gateway for DappCreator success");
    // await _treasuryContract.setNewGateway(_gatewayNFT.address);
    // await new Promise((r) => setTimeout(r, 15000));
    // console.log("treasury set GatewayNFT success");

    // await _gatewayNFT.authorizeNFT(_creator.address);
    // console.log("GatewayNFT authorize DappCreator Success");
    // await new Promise((r) => setTimeout(r, 15000));
    await _gatewayNFT.authorizeNFT(_treasuryContract.address);
    console.log("GatewayNFT authorize DappCreator & Treasury Success");
  }

  /**
   *      10. Create new Collection
   */
  if (deployments.create_new) {
    await _factory.createCampaign(
      //   1,
      //   process.env.CampaignPaymentAddress,
      //   "https://static.esollabs.com/nft/metadata",
      //   _iUSDT.address,
      //   "NFTC1",
      //   "NFT Campaign",
      //   [
      //     [1, 0, (1 * 10 ** 18).toString()],
      //     [2, 3000, (2 * 10 ** 18).toString()],
      //     [3, 2000, (3 * 10 ** 18).toString()],
      //   ]
      1,
      "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B",
      "link",
      _iUSDT.address,
      "mm",
      "meme",
      [["1", "10000", "10000"]]
    );
  }

  /**
   *      11. Get collection address
   */
  var _collectionAddress = await _factory.getCollectionAddress(4);
  console.log("9. collection[0] : ", _collectionAddress);
  // wf("Collection[0]", _collectionAddress);

  /**
   *      9. Config one for colleciton
   */
  // if (deployments.factory_config) {
  //     await _factory.configCollection(
  //         _collectionAddress,
  //         0,
  //         (20 * 10 ** 18).toString()
  //     );
  // }

  /**
   *      10. Create new Box
   */
  // if (deployments.create_new_box) {
  //     await _factory.createBox(
  //         "Testing Box",
  //         "TB",
  //         "https://bafkreidfudijruu7e4mjgehgr3szr3rexyqlno3wafg3qqgtmbyj6i7d3y.ipfs.w3s.link/",
  //         100,
  //         "0xF06d7139cD8708de3e9cB2E732A8A158039ebd44", // Katana-Treasury-2
  //         2000,
  //         _collectionAddress
  //     );
  // }

  /**
   *      11. Get box address
   */
  // var _boxAddress = await _factory.getBoxAddress(0);
  // console.log("11. box[0] : ", _boxAddress);
  // wf("Box[0]", _boxAddress);

  /**
   *      12.. Config box
   */
  // if (deployments.factory_config_box) {
  //     await _factory.configBox(
  //         _boxAddress,
  //         (25 * 10 ** 18).toString(),
  //         100
  //     );
  // }
};

// https://static.esollabs.com/metadata/0xee755fa918239826e13bff64ff0184457dc13506/1.json
// https://static.esollabs.com/metadata/collection/0xee755fa918239826e13bff64ff0184457dc13506/1.json
