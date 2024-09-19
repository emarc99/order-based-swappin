import { time, loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("SwapContract", function () {
  // Fixture to deploy the SwapContract and setup accounts
  async function deploySwapContractFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, user1, user2] = await hre.ethers.getSigners();

    const SwapContract = await hre.ethers.getContractFactory("SwapOrder");
    const swapContract = await SwapContract.deploy();

    // Deploy mock token contracts for testing (e.g., MyToken contract)
    const Token = await hre.ethers.getContractFactory("MyToken");
    const token1 = await Token.deploy();
    const token2 = await Token.deploy();

    return { swapContract, token1, token2, owner, user1, user2 };
  }

  describe("Order Creation", function () {
    it("Should allow user1 to create an order", async function () {
      const { swapContract, token1, user1 } = await loadFixture(deploySwapContractFixture);

      // User1 approves the swap contract to spend their tokens
      await token1.connect(user1).approve(swapContract, 100);

      // Create order: user1 deposits 100 tokens, requesting 20 of another token
      await swapContract.connect(user1).createOrder(token1, 100, token1, 20);

      // Verify the order was created correctly
      const order = await swapContract.orders(0);
      expect(order.depositedAmount).to.equal(100);
      expect(order.paymentAmount).to.equal(20);
    });
  });

  describe("Token Approval", function () {
    it("Should allow user1 to approve tokens for the swap contract", async function () {
      const { token1, swapContract, user1 } = await loadFixture(deploySwapContractFixture);

      // Approve 100 tokens for the swap contract
      await token1.connect(user1).approve(swapContract, 100);

      const allowance = await token1.allowance(user1.address, swapContract);
      expect(allowance).to.equal(100);
    });
  });

  describe("Purchase Tokens", function () {
    it("Should allow user2 to purchase tokens from the order", async function () {
      const { swapContract, token1, token2, user1, user2 } = await loadFixture(deploySwapContractFixture);

      // User1 creates an order, deposits 100 tokens
      await token1.connect(user1).approve(swapContract, 100);
      await swapContract.connect(user1).createOrder(token1, 100, token2, 20);

      // User2 purchases 50 tokens by paying
      await token2.connect(user2).approve(swapContract, 10);
      await swapContract.connect(user2).purchaseTokens(0, 50, token2, 10);

      // Verify that the balances have been updated accordingly
      expect(await token1.balanceOf(user2.address)).to.equal(50);
      expect(await token2.balanceOf(user1.address)).to.equal(10);
    });
  });

  describe("Token Transfer", function () {
    it("Should allow approved spender to transfer tokens on behalf of user", async function () {
      const { token1, swapContract, user1, user2 } = await loadFixture(deploySwapContractFixture);

      // User1 approves user2 to spend 50 tokens
      await token1.connect(user1).approve(user2.address, 50);

      // User2 transfers 50 tokens from user1 to themselves
      await swapContract.connect(user2).transferFrom(user1.address, user2.address, token1, 50);

      // Verify the balance updates
      expect(await token1.balanceOf(user2.address)).to.equal(50);
      expect(await token1.balanceOf(user1.address)).to.equal(0);
    });
  });

  describe("Edge Case Tests", function () {
    it("Should revert if user2 tries to purchase more tokens than available in the order", async function () {
      const { swapContract, token1, token2, user1, user2 } = await loadFixture(deploySwapContractFixture);

      // User1 creates an order, deposits 100 tokens
      await token1.connect(user1).approve(swapContract, 100);
      await swapContract.connect(user1).createOrder(token1, 100, token2, 20);

      // User2 tries to purchase more tokens than available
      await token2.connect(user2).approve(swapContract, 30);
      await expect(
        swapContract.connect(user2).purchaseTokens(0, 150, token2, 30)
      ).to.be.revertedWith("Not enough tokens available in the order");
    });

    it("Should revert if user tries to transfer more tokens than approved", async function () {
      const { token1, swapContract, user1, user2 } = await loadFixture(deploySwapContractFixture);

      // User1 approves user2 to spend 50 tokens
      await token1.connect(user1).approve(user2.address, 50);

      // User2 tries to transfer 60 tokens (more than approved)
      await expect(
        swapContract.connect(user2).transferFrom(user1.address, user2.address, token1, 60)
      ).to.be.revertedWith("Allowance too low");
    });
  });
});