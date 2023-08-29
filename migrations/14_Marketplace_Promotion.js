const BN = require('bn.js');

const Promotion = artifacts.require("Promotion");

const debug = "true";

const ZERO = new BN(0);
const ONE = new BN(1);
const TWO = new BN(2);
const THREE = new BN(3);

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

module.exports = async function (deployer, network) {
    if (network == "test" || network == "development")
        return;
    require('dotenv').config();

    const {
        OWNER,
        SIGNER,
        FEE_RECEIVER
    } = process.env;
    
    await deployer.deploy(
        Promotion, SIGNER, FEE_RECEIVER
    );

    let PromotionInst = await Promotion.deployed();
    await PromotionInst.transferOwnership(OWNER);
    console.log("Promotion =", PromotionInst.address);
};