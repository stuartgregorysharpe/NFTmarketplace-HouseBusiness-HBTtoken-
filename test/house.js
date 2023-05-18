const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HouseBusiness", function () {
  let HouseBusiness;
  let houseBusiness;

  beforeEach(async function () {
    HouseBusiness = await ethers.getContractFactory("HouseBusiness");
    houseBusiness = await HouseBusiness.deploy();
    await houseBusiness.deployed();
  });

  it("should mint a new house", async function () {
    await houseBusiness.mintHouse(
      "My House",
      "https://ipfs.io/ipfs/QmYy7VqENnEJNfbrNYxxeRvZLzHWZ4eC4sKsHZwyEdyTHc",
      "Residential",
      "This is my first house!"
    );
    const house = await houseBusiness.allHouses(1);
    expect(house.tokenName).to.equal("My House");
    expect(house.tokenURI).to.equal(
      "https://ipfs.io/ipfs/QmYy7VqENnEJNfbrNYxxeRvZLzHWZ4eC4sKsHZwyEdyTHc"
    );
    expect(house.price).to.equal(0);
    expect(house.contributor.currentOwner).to.equal(await ethers.getSigner(0).getAddress());
  });

  it("should add history to a house", async function () {
    await houseBusiness.mintHouse(
      "My House",
      "https://ipfs.io/ipfs/QmYy7VqENnEJNfbrNYxxeRvZLzHWZ4eC4sKsHZwyEdyTHc",
      "Residential",
      "This is my first house!"
    );
    await houseBusiness.addHistory(
      1,
      0,
      1,
      "https://ipfs.io/ipfs/QmYy7VqENnEJNfbrNYxxeRvZLzHWZ4eC4sKsHZwyEdyTHc",
      "My Brand",
      "This is the history of my house",
      "This is the description of my brand",
      "My Brand Type",
      2022
    );
    const history = await houseBusiness.houseHistories(1, 1);
    expect(history.houseID).to.equal(1);
    expect(history.historyTypeId).to.equal(1);
    expect(history.houseImg).to.equal(
      "https://ipfs.io/ipfs/QmYy7VqENnEJNfbrNYxxeRvZLzHWZ4eC4sKsHZwyEdyTHc"
    );
    expect(history.desc).to.equal("This is the description of my brand");
    expect(history.history).to.equal("This is the history of my house");
  });
});
