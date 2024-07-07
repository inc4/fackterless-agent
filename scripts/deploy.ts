import {ethers} from "hardhat";

async function main() {
  if (!process.env.ORACLE_ADDRESS) {
    throw new Error("ORACLE_ADDRESS env variable is not set.");
  }
  if (!process.env.STORAGE_ADDRESS) {
    throw new Error("STORAGE_ADDRESS env variable is not set.");
  }
  const oracleAddress: string = process.env.ORACLE_ADDRESS;
  const storageAddress: string = process.env.STORAGE_ADDRESS;

  const agent = await ethers.deployContract("Agent", [oracleAddress, storageAddress], {});
  await agent.waitForDeployment();

  console.log(`Contract deployed to ${agent.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
