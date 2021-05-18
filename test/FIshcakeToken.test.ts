import { ethers } from "hardhat";
import { expect } from "chai";

describe("FishcakeToken", function () {
  before(async function () {
    this.FishcakeToken = await ethers.getContractFactory("FishcakeToken");
    this.signers = await ethers.getSigners();

    this.alice = this.signers[0];
    this.bob = this.signers[1];
    this.carol = this.signers[2];
  });

  beforeEach(async function () {
    this.fishcake = await this.FishcakeToken.deploy();

    await this.fishcake.deployed();
  });

  it("should have correct name and symbol and decimal", async function () {
    const name = await this.fishcake.name();
    const symbol = await this.fishcake.symbol();
    const decimals = await this.fishcake.decimals();
    expect(name, "FishcakeToken");
    expect(symbol, "FISHCAKE");
    expect(decimals, "18");
  });
});
