const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const { id } = require("ethers/lib/utils");
const utils = ethers.utils;

describe("Test", function () {
  // get the contract instance
  let wibuToken;
  let owner;
  let addres_recipient;
  beforeEach(async function () {
    const Configurations = await ethers.getContractFactory("Configurations");
    configurations = await Configurations.attach(process.env.Configurations);
    console.log("configurations address: ", configurations.address);

    const Token = await ethers.getContractFactory("USDT");
    token = await Token.attach(process.env.USDT);

    // const InZCampaignFactory = await ethers.getContractFactory(
    //   "InZCampaignFactory"
    // );
    // inZCampaignFactory = await InZCampaignFactory.attach(
    //   process.env.InZCampaignFactory
    // );
    // console.log("inZCampaignFactory address: ", inZCampaignFactory.address);

    const DaapNFTCreator = await ethers.getContractFactory("DaapNFTCreator");
    daapNFTCreator = await DaapNFTCreator.attach(
      "0x7e75d72AAcF09De4D221a81892f5d3cb2Cd3b4A5"
    );
    console.log("daapNFTCreator address: ", daapNFTCreator.address);

    [owner] = await ethers.getSigners();
    console.log("owner address: ", owner.address);
  });
  describe("Transactions", function () {
    // it("tranfer token", async function () {
    //   const result = await token.transfer(
    //     "0x469f72990944a8b60664A2e5185635b266E826b0",
    //     utils.parseEther("1500000")
    //   );
    //   console.log("result: ", result);
    // });
    // it("create collection ", async function () {
    //   const result = await inZCampaignFactory.createCampaign(
    //     1,
    //     "0x469f72990944a8b60664A2e5185635b266E826b0",
    //     "link",
    //     token.address,
    //     "mm",
    //     "meme",
    //     [["1", "1000000000000", "1000000000000"]]
    //   );
    //   console.log("result: ", result);
    // });
    // it("Appove from signers for daapnftcreator", async function () {
    //   console.log("token address: ", token.address);
    //   await token.approve(daapNFTCreator.address, 100000);
    // });
    // it("getPayTokenCollection", async function () {
    //   const result = await configurations.payTokenCollection(
    //     "0x0dBA15a48075F4E59d316e78030EB8Eb3Dda030f"
    //   );
    //   console.log("result: ", result.toString());
    //   expect(result).to.equal(token.address);
    // });
    // it("DaapNFTCreator", async function () {
    //   const _nftCollection = "0x9a16d81055e82174f230384d983960adfa0de7e5";
    //   console.log("DaapNFTCreator: ", daapNFTCreator.address);
    //   flag = false;
    //   const signature = [
    //     27,
    //     "0x8e55ef01f9c76a0f53348470094c22353c199c798678812eebb4a8e9ad33dccd",
    //     "0x6ff8583bd26492cbea3cfe7d81d951a500498fc8f91f31fe5447dc0050227b43",
    //     1693221896,
    //   ];
    //   // console.log("signature: ", await daapNFTCreator.signer);
    //   const result = await daapNFTCreator.makeMintingAction(
    //     _nftCollection,
    //     1,
    //     1,
    //     0,
    //     500000000000000,
    //     flag,
    //     signature,
    //     "780248c8-9eaa-43ec-b6f9-6cbb703bf23d",
    //     owner.address,
    //     {
    //       value: utils.parseEther("0.001"),
    //     }
    //   );
    //   console.log("result: ", result);
    // });

    it("should withdraw", async function () {
      const result = await daapNFTCreator.withdraw();
      console.log("result: ", result);
    });
  });
});

// [27, "0x161c4562ffc7bb3266b560944d2bbbfe9f59b7c93c120f264ce5afa24a24c97a", "0x25727b2d8e83ef7f7e223e83b3db2ed99236bd175cd75cd7d5fe65391c296f12", 1688964733]
