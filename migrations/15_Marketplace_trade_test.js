const BN = require('bn.js');

const Exchange = artifacts.require("Exchange");

const debug = "true";

const ZERO = new BN(0);
const ONE = new BN(1);
const TWO = new BN(2);
const THREE = new BN(3);

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    if (network == "test" || network == "development")
        return;

    require('dotenv').config();

    const {
        OWNER,
        SIGNER
    } = process.env;

    var ExchangeInst = await Exchange.at('0xc913c1bD11d94B5C299Ad482484ab8168bEA4F1f');
    await ExchangeInst.trade(
        4,
        ["0x3F3450321D31cED280D7A79f93684d42a2791271","0x2Bcd32d6a207446Bcb8F45cFd6b5Fb2F323680C8"],
        ["0x489cCe427Fe7bAC634D2B22224e07Aa4BEF7E525","0xb902aEf8168c87e2eE2625CD34b1268f9e87bF8D"],
        [1,0],
        [],
        [(100000000000000000000).toString()],
        1681556310,
        "0x777ea8a72be6cf7da66f81f91aad00f474c3cfafa19f24f5f28f6e4737b7b1743c006736c689b859a55e6b1a3145df0928ad08eac8d4e923b5c1b1aa534963e11c"
    );
    console.log("Trade");
};