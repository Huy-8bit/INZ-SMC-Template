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

/**
 * Write address of deployed contracts to a file named 'address.txt' in root folder
 * @param {string} name
 * @param {string} address
 */
function wf(name, address) {
  fs.appendFileSync("address.txt", name + "=" + address);
  fs.appendFileSync("address.txt", "\r\n");
}

async function inzTokenApprove({
  inzTokenInstance,
  web3,
  spender,
  account,
  amount,
}) {
  // NOTE: Send token from owner to address 2
  await inzTokenInstance.approve(
    spender,
    web3.utils.toWei(amount.toString(), "ether"),
    {
      from: account,
    }
  );

  console.log(`inzTokenApprove ${account} with: ${amount}`);
}

async function inzTokenBalanceOf({ inzTokenInstance, account }) {
  const balance = await inzTokenInstance.balanceOf(account);
  return balance;
}

async function inzTokenTransfer({
  inzTokenInstance,
  web3,
  fromAccount,
  toAccount,
  amount,
}) {
  let balance = await inzTokenBalanceOf({
    inzTokenInstance,
    account: toAccount,
  });
  console.log(
    `inzTokenTransfer ${toAccount} before: ${web3.utils.fromWei(
      balance.toString(),
      "ether"
    )}`
  );
  // NOTE: Send token from owner to address 2
  await inzTokenInstance.transfer(
    toAccount,
    web3.utils.toWei(amount.toString(), "ether"),
    {
      from: fromAccount,
    }
  );

  balance = await inzTokenBalanceOf({
    inzTokenInstance,
    account: toAccount,
  });
  console.log(
    `inzTokenTransfer ${toAccount} after: ${web3.utils.fromWei(
      balance.toString(),
      "ether"
    )}`
  );
}

async function posDepositToken({
  inzTokenInstance,
  inzPosInstance,
  web3,
  account,
  amount,
  callBackData,
}) {
  let balanceAccount = await inzTokenBalanceOf({
    inzTokenInstance,
    account,
  });

  console.log(
    "posDepositToken before: ",
    web3.utils.fromWei(balanceAccount.toString(), "ether")
  );

  await inzTokenInstance.approve(inzTokenInstance.address, balanceAccount, {
    from: account,
  });

  await inzPosInstance.depositToken(
    inzTokenInstance.address,
    web3.utils.toWei(amount.toString(), "ether"),
    callBackData,
    {
      from: account,
    }
  );

  balanceAccount = await inzTokenBalanceOf({
    inzTokenInstance,
    account,
  });

  console.log(
    "posDepositToken after: ",
    web3.utils.fromWei(balanceAccount.toString(), "ether")
  );
}

async function posGetBalance({ inzPosInstance, web3, tokenAddress, account }) {
  const posBalance = await inzPosInstance.getBalance(tokenAddress, {
    from: account,
  });
  console.log(
    `posGetBalance balance: ${web3.utils.fromWei(posBalance, "ether")}`
  );
  return posBalance;
}

async function posWithdraw({
  inzPosInstance,
  web3,
  account,
  tokenAddress,
  amount,
}) {
  await inzPosInstance.withdrawToken(
    tokenAddress,
    web3.utils.toWei(amount.toString(), "ether"),
    {
      from: account,
    }
  );
}

async function posTransferToken({
  inzPosInstance,
  inzTokenInstance,
  web3,
  tokenAddress,
  fromAccount,
  toAccount,
  amount,
}) {
  let balance = await inzTokenBalanceOf({
    inzTokenInstance,
    account: toAccount,
  });
  console.log(
    `posTransferToken before transfer:  ${web3.utils.fromWei(
      balance.toString(),
      "ether"
    )}`
  );
  await inzPosInstance.transferToken(
    toAccount,
    tokenAddress,
    web3.utils.toWei(amount.toString(), "ether"),
    {
      from: fromAccount,
    }
  );
  console.log(
    `posTransferToken after transfer: ${web3.utils.fromWei(
      balance.toString(),
      "ether"
    )}`
  );
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
  const INZ_TOKEN_ADDRESS = process.env.INZ_TOKEN_ADDRESS;
  const INZ_POS_ADDRESS = process.env.INZ_POS_ADDRESS;

  const ACC1_KEY = process.env.ACC1_KEY;
  const ACC2_KEY = process.env.ACC2_KEY;

  const RPC = "https://polygon-mumbai-bor.publicnode.com";

  const provider = new HDWalletProvider({
    privateKeys: [ACC1_KEY, ACC2_KEY],
    url: RPC,
  });

  const accountAddresses = provider.getAddresses();

  const web3 = new Web3(provider);
  InZToken.setProvider(provider);
  InZPos.setProvider(provider);

  const inzTokenInstance = await InZToken.at(INZ_TOKEN_ADDRESS);
  const inzPosInstance = await InZPos.at(INZ_POS_ADDRESS);

  // await inzTokenTransfer({
  //   inzTokenInstance,
  //   web3,
  //   fromAccount: accountAddresses[0],
  //   toAccount: accountAddresses[1],
  //   amount: 100,
  // });

  // // NOTE: deposit from account
  // await posDepositToken({
  //   inzTokenInstance,
  //   inzPosInstance,
  //   web3,
  //   account: accountAddresses[1],
  //   amount: 10,
  //   callBackData: "callback2",
  // });

  // await posGetBalance({
  //   inzPosInstance,
  //   web3,
  //   tokenAddress: INZ_TOKEN_ADDRESS,
  //   account: accountAddresses[0],
  // });

  // await posWithdraw({
  //   inzPosInstance,
  //   web3,
  //   account: accountAddresses[0],
  //   tokenAddress: INZ_TOKEN_ADDRESS,
  //   amount: 10,
  // });

  // await posTransferToken({
  //   inzPosInstance,
  //   inzTokenInstance,
  //   web3,
  //   tokenAddress: INZ_TOKEN_ADDRESS,
  //   fromAccount: accountAddresses[1],
  //   toAccount: accountAddresses[0],
  //   amount: 10,
  // });
};
