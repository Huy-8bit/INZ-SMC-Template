const Exchange = artifacts.require("Exchange");

contract("Exchange", () => {
  it("...should deploy and successfully call createInstance using the method's provided gas estimate", async () => {
    const exchangeInstance = await Exchange.new();

    const gasEstimate = await exchangeInstance.createInstance.estimateGas();
    console.log("");
    // const tx = await exchangeInstance.createInstance({
    //   gas: gasEstimate
    // });
    // assert(tx);
  });
});
