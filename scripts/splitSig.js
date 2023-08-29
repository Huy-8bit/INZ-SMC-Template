const { ethers } = require("ethers");

function split_sig() {
  var _sig =
    "0x8e55ef01f9c76a0f53348470094c22353c199c798678812eebb4a8e9ad33dccd6ff8583bd26492cbea3cfe7d81d951a500498fc8f91f31fe5447dc0050227b431b";
  const { v, r, s } = ethers.utils.splitSignature(_sig);
  console.log(`[${v}, "${r}", "${s}", 1693221896]`);
}

split_sig();
// [28, "0x5378fb195fc690e72cac2dd72d736caf71053fcfd46b2a4ab687b13755f96764", "0x654c80b158fc6e0c8cf475a21225c2d554e0fd65bba1eaccfc2499e1b0d1976d", 1669148853]
