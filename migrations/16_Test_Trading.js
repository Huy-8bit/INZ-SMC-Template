const console = require("console");
const fs = require("fs");
const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require("web3");

var Exchange = artifacts.require("Exchange");
var USDT = artifacts.require("BasicERC20");

function wf(name, address) {
  fs.appendFileSync("address.txt", name + "=" + address);
  fs.appendFileSync("address.txt", "\r\n");
}

module.exports = async function (deployer, network, accounts) {
  let account = deployer.options?.from || accounts[0];
  if (network == "test" || network == "development") return;

  require("dotenv").config();
  const { ACC1_KEY, ACC2_KEY } = process.env;
  const RPC = "https://polygon-mumbai-bor.publicnode.com";
  const provider = new HDWalletProvider({
    privateKeys: [ACC1_KEY, ACC2_KEY],
    url: RPC,
  });
  const accountAddresses = provider.getAddresses();

  const web3 = new Web3(provider);
  USDT.setProvider(provider);

  var iUSDT = await USDT.at(process.env.iUSDT);
  // var amount = 100;
  // await iUSDT.transfer(
  //   accountAddresses[1],
  //   web3.utils.toWei(amount.toString(), "ether"),
  //   { from: accountAddresses[0] }
  // );
  // console.log("Transfer success.");

  var balance = await iUSDT.balanceOf(
    "0x495922E118bCC32C69Bedd3c48Fa885af22d5421"
  );

  console.log(
    `Balance before buy: ${web3.utils.fromWei(balance.toString(), "ether")}`
  );

  await iUSDT.approve("0x495922E118bCC32C69Bedd3c48Fa885af22d5421", balance, {
    from: "0xb2c4E0862c9252F9a1bD712e329fD13Cfc7A7a15",
  });

  var allowanceAmount = await iUSDT.allowance(
    "0xb2c4E0862c9252F9a1bD712e329fD13Cfc7A7a15",
    "0x495922E118bCC32C69Bedd3c48Fa885af22d5421"
  );

  console.log(
    `Allowance amount is: ${web3.utils.fromWei(
      allowanceAmount.toString(),
      "ether"
    )}`
  );

  // var iExchange = await Exchange.at(process.env.Exchange);
  // await iExchange.trade(
  //   1,
  //   [
  //     "0xb2c4E0862c9252F9a1bD712e329fD13Cfc7A7a15",
  //     "0x495922E118bCC32C69Bedd3c48Fa885af22d5421",
  //   ],
  //   [
  //     "0xc81B84301cF0f46de53cbF6f6d3Ed97f8f9F8d65",
  //     "0x104f3555C97E1DB6ff6f36FEA2fd4f23dD16cf98",
  //   ],
  //   [1, 1],
  //   [],
  //   [2 * 10 ** 15],
  //   1695339799,
  //   "0xab43a16d23d3872dda6285c8d18782b9f22499ac7730b86eca5937f20e6d26677a527fe9ae67ead42a213aeee9f567a20f7e0290e21e3da37fa0b23f856d46401c",
  //   { from: accountAddresses[1] }
  // );
  // console.log("Trade NFT success.");

  // var balance = await _iUSDT.balanceOf(
  //   "0x495922E118bCC32C69Bedd3c48Fa885af22d5421"
  // );

  // console.log(
  //   `Balance after buy: ${web3.utils.fromWei(balance.toString(), "ether")}`
  // );
};
