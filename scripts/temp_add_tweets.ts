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
    console.log("Agent deployed to:", agent.target);

    let tx, id;
    id = "455937214";
    tx = await agent.temp_addUser(id, "layahheilpern"); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809291629091500487", false); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809259272712401404", true); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809258662869049555", false); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809237823909765603", false); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809230804603519057", true); await tx.wait();

    id = "1559599104858017792";
    tx = await agent.temp_addUser(id, "cryptoljebb"); await tx.wait();
    tx = await agent.temp_addTweet(id, "1559601949200175105", true); await tx.wait();

    id = "1150790822813560833";
    tx = await agent.temp_addUser(id, "girlgone_crypto"); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809283959022637215", true); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809250275393495394", true); await tx.wait();
    tx = await agent.temp_addTweet(id, "1809012992467685398", true); await tx.wait();
    tx = await agent.temp_addTweet(id, "1807861718414250456", true); await tx.wait();
    tx = await agent.temp_addTweet(id, "1807531636310901017", true); await tx.wait();

    console.log(await agent.userIds());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
