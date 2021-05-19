import { expect } from "chai";
import { ethers } from "hardhat";

import { FishcakeToken, FishcakeToken__factory } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("FishcakeToken", () => {
  let fishcake: FishcakeToken;

  let account: SignerWithAddress[];

  before(async () => {
    account = await ethers.getSigners();
  });

  beforeEach(async function () {
    const [owner] = account;

    const FishcakeFactory = (await ethers.getContractFactory(
      "FishcakeToken",
      owner
    )) as FishcakeToken__factory;

    fishcake = await FishcakeFactory.deploy();

    await fishcake.deployed;
  });

  it("should have correct name, symbol and decimal", async () => {
    const name = await fishcake.name();
    const symbol = await fishcake.symbol();
    const decimal = await fishcake.decimals();

    expect(name, "FishcakeToken");
    expect(symbol, "FISHCAKE");
    expect(decimal, "18");
  });

  it("should only allow owner to mint token", async () => {
    //eslint-disable-next-line
    const [owner, alice, bob] = account;

    await fishcake.mint(owner.address, "200");
    await fishcake.mint(alice.address, "100");

    await expect(
      fishcake.connect(bob).mint(bob.address, "100")
    ).to.be.revertedWith("revert Ownable: caller is not the owner");

    const totalSupply = await fishcake.totalSupply();
    const ownerBal = await fishcake.balanceOf(owner.address);
    const aliceBal = await fishcake.balanceOf(alice.address);
    const bobBal = await fishcake.balanceOf(bob.address);

    expect(totalSupply).to.be.equal("300");
    expect(ownerBal).to.be.equal("200");
    expect(aliceBal).to.be.equal("100");
    expect(bobBal).to.be.equal("0");
  });

  it("should token transfer properly", async () => {
    const [owner, alice, bob] = account;

    await fishcake.mint(owner.address, "200");
    await fishcake.mint(alice.address, "100");

    await fishcake.transfer(bob.address, "50");
    await fishcake.connect(alice).transfer(bob.address, "50");

    const totalSupply = await fishcake.totalSupply();
    const ownerBal = await fishcake.balanceOf(owner.address);
    const aliceBal = await fishcake.balanceOf(alice.address);
    const bobBal = await fishcake.balanceOf(bob.address);

    expect(totalSupply).to.be.equal("300");
    expect(ownerBal).to.be.equal("150");
    expect(aliceBal).to.be.equal("50");
    expect(bobBal).to.be.equal("100");
  });

  it("should fail if you try do bad transfer", async () => {
    const [owner, alice, bob] = account;

    await fishcake.mint(owner.address, "100");

    await expect(fishcake.transfer(bob.address, "101")).to.be.revertedWith(
      "ERC20: transfer amount exceeds balance"
    );
    await expect(
      fishcake.connect(alice).transfer(bob.address, "100")
    ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
  });
});
