const fs = require("fs");
const Exchange = artifacts.require("ExchangeUpgradeable");
const ExchangeProxy = artifacts.require("ExchangeProxy");
const BasicNFT1155 = artifacts.require("BasicERC1155");
const BasictNFT721 = artifacts.require("BasicNft");

function wf(name, address) {
  fs.appendFileSync("address.txt", name + "=" + address);
  fs.appendFileSync("address.txt", "\r\n");
}

const settings = {
  newNFT: false,
  isERC721: true,
};

var BasicNFT = BasicNFT1155;
if (settings.isERC721) {
  BasicNFT = BasictNFT721;
}
module.exports = async function (deployer, network, accounts) {
  let account = deployer.options?.from || accounts[0];
  if (network == "test" || network == "development") return;

  require("dotenv").config();
  // Owner and Signer of Exchange contract
  const { OWNER, SIGNER } = process.env;

  // ACC1 and ACC2 to trade NFT
  const { ACC1, ACC2 } = process.env;

  let ExchangeProxyAddr = process.env.ExchangeProxy;
  var iExchange = await Exchange.at(ExchangeProxyAddr);
  console.log("get contract address done");

  // NFT to test
  if (settings.newNFT) {
    await deployer.deploy(BasicNFT);
    var iBasicNFT = await BasicNFT.deployed();
    wf("BasicNFT", iBasicNFT.address);
    await iBasicNFT.mintNft({ from: ACC1 });
  } else {
    let BasicNFTAddr = process.env.BasicNFT;
    var iBasicNFT = await BasicNFT.at(BasicNFTAddr);
  }

  // Test for ERC721
  if (settings.isERC721) {
    // await iBasicNFT.approve(iExchange.address, 0, { from: ACC1 });
    // console.log("Approve for Exchange contract success");

    console.log("Owner of NFT before: ", await iBasicNFT.ownerOf(0));

    await iExchange.claimNFT(
      1,
      [ACC2, ACC1],
      iBasicNFT.address,
      [0, 0],
      "1692603733",
      "0x4dff782fb438a46e9f2cc28c599846b38996068886d394847edf60227902d9951ed0ee8ec661501318a004b831d693e57ca5753daded78e04b9bb437b767f5101c",
      { from: ACC1 }
    );
    console.log("Claim NFT success");

    console.log("Owner of NFT after: ", await iBasicNFT.ownerOf(0));
  }

  // Test for ERC1155
  if (!settings.isERC721) {
    // Require ACC1 and deployer the same account
    await iBasicNFT.setApprovalForAll(iExchange.address, true, { from: ACC1 });
    // console.log(
    //   "Account 2 balance of the NFT before: ",
    //   await iBasicNFT.balanceOf(ACC2, 2)
    // );

    // await iExchange.claimNFT(
    //   2,
    //   [ACC1, ACC2],
    //   iBasicNFT.address,
    //   [2, 5],
    //   "0x630487ec07ea8f4176b69047b93e62ac3210791986f4907aea115a4694e6303c39267b84e644b3fc47bab18b598dea2b4d725592d5414d3a6f523ed86dd9bd1b1b",
    //   {
    //     from: ACC2,
    //   }
    // );
    // console.log("Claim NFT success");

    // console.log(
    //   "Account 2 balance of the NFT after: ",
    //   await iBasicNFT.balanceOf(ACC2, 2)
    // );
  }
};
