const BN = require('bn.js');

const FactoryERC721 = artifacts.require("FactoryERC721");

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
        SIGNER
    } = process.env;
    
    await deployer.deploy(
        FactoryERC721, SIGNER
    );

    let FactoryERC721Inst = await FactoryERC721.deployed();
    await FactoryERC721Inst.transferOwnership(OWNER);
    console.log("FactoryERC721 =", FactoryERC721Inst.address);
};