const ethers = require('ethers')

let address = "0xa0aCc9F312FaDe7aC5A1Ef189f4Da8763592ef25";
let etherscanProvider = new ethers.providers.Web3Provider(network="https://goerli.base.org");

etherscanProvider.getHistory(address).then((history) => {
    history.forEach((tx) => {
        console.log(tx);
    })
});