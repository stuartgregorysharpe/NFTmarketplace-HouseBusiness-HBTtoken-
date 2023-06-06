// const { expect } = require("chai");
// const { ethers } = require("ethers");

// describe("Operator", function () {
//   let operator;
//   let hbToken;
//   let user;
//   let contractAddress;
//   let data;
//   let gasFee;

//   beforeEach(async function () {
//     // Create a new MockProvider instance
//     const provider = new ethers.providers.MockProvider();

//     const HBToken = await ethers.getContractFactory("HouseBusinessToken");
//     hbToken = await HBToken.deploy();
//     await hbToken.deployed();

//     const Operator = await ethers.getContractFactory("Operator");
//     operator = await Operator.deploy(hbToken.address);
//     await operator.deployed();

//     const HouseDoc = await ethers.getContractFactory("HouseDoc");
//     houseDoc = await HouseDoc.deploy(hbToken.address);
//     await houseDoc.deployed();

//     user = provider.getSigner(0);

//     await hbToken.connect(user).approve(operator.address, ethers.utils.parseEther("10"));
//     await operator.connect(user).deposit(ethers.utils.parseEther("10"));
//     await houseDoc.connect(user).setOperatorAddress(operator.address);

//     contractAddress = houseDoc.address;
//     const companyName = "Example Company";
//     const contractType = 1;
//     const contractSigner = user.address;
//     const contractURI = "https://example.com/contract";
//     const dateFrom = 1632880800; // October 1, 2021, 00:00:00 UTC
//     const dateTo = 1632967200; // October 2, 2021, 00:00:00 UTC
//     const agreedPrice = ethers.utils.parseEther("1");
//     const currency = "ETH";
//     // data = houseDoc.interface.encodeFunctionData(
//     //   'hdCreation',
//     //   [companyName, contractType, contractSigner, contractURI, dateFrom, dateTo, agreedPrice, currency, user.address]
//     // );

//     data = houseDoc.interface.encodeFunctionData(
//       'addContractSigner',
//       [1, user.address]
//     );
//     gasFee = 100;
//   });

//   describe("callContract", function () {
//     // it("should revert if the contract is not authorized", async function () {
//     //   await expect(
//     //     operator.callContract(contractAddress, data, gasFee, user.address)
//     //   ).to.be.revertedWith("Contract not authorized");
//     // });

//     // it("should revert if the user has insufficient balance", async function () {
//     //   await operator.authorizeContracts([contractAddress]);

//     //   await expect(
//     //     operator.callContract(contractAddress, data, gasFee, user.address)
//     //   ).to.be.revertedWith("Insufficient balance");
//     // });

//     it("should call the contract and deduct the gas fee from the user's balance", async function () {
//       await operator.authorizeContracts([contractAddress]);
//       // await hbToken.mint(user.address, gasFee);

//       const initialBalance = await operator.balanceOf(user.address);

//       console.log(operator.address);
//       console.log(await houseDoc.operatorAddress());

//       const txdata = operator.interface.encodeFunctionData('callContract', [contractAddress, data, gasFee, user.address]);

//       // Create a new transaction object
//       const tx = {
//         to: operator.address,
//         data: txdata,
//       };

//       // Sign the transaction
//       const signedTx = await user.signTransaction(tx);
//       const finalBalance = await operator.balanceOf(user.address);

//       expect(finalBalance).to.equal(initialBalance.sub(gasFee));
//     });
//   });
// });