const {ethers} = require("hardhat");
import { Agent__factory } from '../typechain-types';

async function main() {
    if (!process.env.ORACLE_ADDRESS) {
        throw new Error("ORACLE_ADDRESS env variable is not set.");
    }
    const oracleAddress: string = process.env.ORACLE_ADDRESS;

    const owner = await ethers.getSigners()[0];
    const agentFactory = await ethers.getContractFactory("Agent", owner);
    const agent = await agentFactory.deploy(oracleAddress);
    await agent.waitForDeployment();

    let tx = await agent.temp_addUser(1234, "alex");
    await tx.wait();
    tx = await agent.temp_addTweet(1234, 101020, true);
    await tx.wait();
    console.log(await agent.users(1234));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
