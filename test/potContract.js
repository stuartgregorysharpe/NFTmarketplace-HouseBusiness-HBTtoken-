const PotLottery = artifacts.require("PotLottery");

contract('PotLottery', (accounts) => {
  it('should get the right swap pair', async () => {
    const potLotteryInstance = await PotLottery.deployed();
    const plspAddr = '0x406e0D28Dea83F7c87850Eed8e9d1d9a57D6fADC';
    const tokens = [
      { name: 'TestToken1', symbol: 'TTok1', address: '0xbde5CB77a3032f547079b802ec3ADdddB6c43973' },
      { name: 'TestToken2', symbol: 'TTok2', address: '0xcd8814D4E3e56a1dFC3a8b75045C77e67AF71963' }
    ]

    await potLotteryInstance.setPLSPAddress(plspAddr);
    for (let i = 0; i < tokens.length; i++) {
      const { name, symbol, address } = tokens[i];
      await potLotteryInstance.addToken(name, symbol, address, 18);
    }
    const data = await potLotteryInstance.swapAccumulatedFees();
    let balance = await web3.eth.getBalance(potLotteryInstance.address)

    console.log('balance: ', data);
    // assert.equal(res0.valueOf(), 10000, "10000 wasn't in the first account");
  });
});
