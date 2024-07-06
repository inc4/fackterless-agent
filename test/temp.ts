import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

describe("Agent", function () {
  async function deploy() {
    const owner = await ethers.getSigners()[0];

    const Oracle = await ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy();

    const Agent = await ethers.getContractFactory("Agent");
    const agent = await Agent.deploy("0x0000000000000000000000000000000000000000");
    await agent.setOracleAddress(oracle.target);

    return {agent, oracle, owner};
  }

  describe("Temporary", function () {
    it("test", async function () {
      const {agent, oracle, owner} = await loadFixture(deploy);
      const addUserTx = await agent.temp_addUser(1234, "alex");
      await addUserTx.wait();
      console.log(await agent.users(1234));
      console.log(await agent.users(1235));
    });
  });
});
