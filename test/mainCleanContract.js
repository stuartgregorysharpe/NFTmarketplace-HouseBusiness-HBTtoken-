// test/MainCleanContract.test.js

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MainCleanContract", function () {
    let mainContract;

    beforeEach(async function () {
        const MainCleanContract = await ethers.getContractFactory("MainCleanContract");
        mainContract = await MainCleanContract.deploy('0xdEf400d6Aa615cedFA34aBa08a7dcb335871Ce39');
        await mainContract.deployed();
    });

    it("should create a new clean contract", async function () {
        // Create a sample contract
        const companyName = "Sample Company";
        const contractType = "Sample Type";
        const [user, contractSigner] = await ethers.getSigners();
        const contractURI = "ipfs://sampleURI";
        const dateFrom = Math.floor(Date.now() / 1000);
        const dateTo = dateFrom + 86400; // 1 day in the future
        const agreedPrice = ethers.utils.parseEther("100");
        const currency = "ETH";

        // Call the ccCreation function
        await mainContract.ccCreation(
            companyName,
            contractType,
            contractSigner.address,
            contractURI,
            dateFrom,
            dateTo,
            agreedPrice,
            currency,
            user.address
        );

        // Verify the created contract details
        const contractsByOwner = await mainContract.getAllContractsByOwner(user.address);
        expect(contractsByOwner.length).to.equal(1);

        const createdContract = contractsByOwner[0];
        expect(createdContract.companyName).to.equal(companyName);
        expect(createdContract.contractType).to.equal(contractType);
        expect(createdContract.contractSigner).to.equal(contractSigner.address);
        expect(createdContract.contractURI).to.equal(contractURI);
        expect(createdContract.dateFrom).to.equal(dateFrom);
        expect(createdContract.dateTo).to.equal(dateTo);
        expect(createdContract.agreedPrice).to.equal(agreedPrice);
        expect(createdContract.currency).to.equal(currency);
        expect(createdContract.creator).to.equal(user.address);
        expect(createdContract.owner).to.equal(user.address);
        expect(createdContract.creatorApproval).to.be.false;
        expect(createdContract.signerApproval).to.be.false;
        expect(createdContract.status).to.equal("pending");
    });
});
