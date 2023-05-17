const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MainCleanContract", function () {
  let Contract;
  let contract;
  let creator;
  let owner;
  let signer;

  before(async function () {
    Contract = await ethers.getContractFactory("MainCleanContract");
    [creator, owner, signer] = await ethers.getSigners();
    contract = await Contract.connect(creator).deploy(owner.address);
    await contract.deployed();
  });

  describe("ccCreation", function () {
    it("should create a new contract", async function () {
      const companyName = "Example Company";
      const contractType = 1;
      const contractSigner = signer.address;
      const contractURI = "https://example.com/contract";
      const dateFrom = 1632880800; // October 1, 2021, 00:00:00 UTC
      const dateTo = 1632967200; // October 2, 2021, 00:00:00 UTC
      const agreedPrice = ethers.utils.parseEther("1");
      const currency = "ETH";
      await expect(() =>
        contract.ccCreation(companyName, contractType, contractSigner, contractURI, dateFrom, dateTo, agreedPrice, currency)
      ).to.changeEtherBalance(creator, ethers.utils.parseEther("0").sub(agreedPrice));
      const cc = await contract.allCleanContracts(1);
      expect(cc.contractId).to.equal(1);
      expect(cc.companyName).to.equal(companyName);
      expect(cc.contractType).to.equal(contractType);
      expect(cc.contractURI).to.equal(contractURI);
      expect(cc.dateFrom).to.equal(dateFrom);
      expect(cc.dateTo).to.equal(dateTo);
      expect(cc.agreedPrice).to.equal(agreedPrice);
      expect(cc.currency).to.equal(currency);
      expect(cc.creator).to.equal(creator.address);
      expect(cc.owner).to.equal(creator.address);
      expect(cc.contractSigner).to.equal(contractSigner);
      expect(cc.creatorApproval).to.be.false;
      expect(cc.creatorSignDate).to.equal(0);
      expect(cc.signerApproval).to.be.false;
      expect(cc.signerSignDate).to.equal(0);
      expect(cc.status).to.equal("pending");
    });

    it("should not create a new contract with invalid data", async function () {
      const companyName = "";
      const contractType = 1;
      const contractSigner = signer.address;
      const contractURI = "https://example.com/contract";
      const dateFrom = 1632967200; // October 2, 2021, 00:00:00 UTC
      const dateTo = 1632880800; // October 1, 2021, 00:00:00 UTC
      const agreedPrice = 0;
      const currency = "ETH";
      await expect(
        contract.ccCreation(companyName, contractType, contractSigner, contractURI, dateFrom, dateTo, agreedPrice, currency)
      ).to.be.revertedWith("Start date must be before end date");
    });
  });

  describe("addContractSigner", function () {
    it("should add a contract signer", async function () {
      const ccID = 1;
      const newSigner = signer.address;
      await expect(
        contract.connect(owner).addContractSigner(ccID, newSigner)
      ).to.be.fulfilled;
      const cc = await contract.allCleanContracts(1);
      expect(cc.contractSigner).to.equal(newSigner);
    });

    it("should not add a contract signer if not the owner", async function () {
      const ccID = 1;
      const newSigner = signer.address;
      await expect(
        contract.connect(signer).addContractSigner(ccID, newSigner)
      ).to.be.revertedWith("Only contract owner can add contract signer");
    });
  });

  describe("sendNotify", function () {
    it("should send a notification", async function () {
      const ccID = 1;
      const notifyReceiver = signer.address;
      const notifyContent = "Example notification";
      await expect(
        contract.connect(owner).sendNotify(notifyReceiver, notifyContent, ccID)
      ).to.be.fulfilled;
      const notifies = await contract.allNotifies(signer.address);
      expect(notifies.length).to.equal(1);
      expect(notifies[0].nSender).to.equal(owner.address);
      expect(notifies[0].nReceiver).to.equal(signer.address);
      expect(notifies[0].ccID).to.equal(ccID);
      expect(notifies[0].notifyContent).to.equal(notifyContent);
      expect(notifies[0].status).to.be.false;
    });

    it("should not send a notification if contract signer not added", async function () {
      const ccID = 1;
      const notifyReceiver = signer.address;
      const notifyContent = "Example notification";
      await expect(
        contract.connect(owner).sendNotify(notifyReceiver, notifyContent, ccID)
      ).to.be.revertedWith("Please add contract signer.");
    });
  });
});