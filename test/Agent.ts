import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

describe("Agent", function () {
    async function deploy() {
        const [owner] = await ethers.getSigners();

        const Oracle = await ethers.getContractFactory("Oracle");
        const oracle = await Oracle.deploy();

        const Storage = await ethers.getContractFactory("Storage");
        const storage = await Storage.deploy();

        const Agent = await ethers.getContractFactory("Agent");
        const agent = await Agent.deploy(oracle.target, storage.target);
        await oracle.updateWhitelist(owner.address, true);

        return {agent, oracle, storage, owner};
    }

    it("Should process tweets", async () => {
        const {agent, oracle, storage, owner} = await loadFixture(deploy);

	await storage.createUser("295218901", "VitalikButerin");
	await storage.addTweet("295218901", "1729251834404249696", "2023-11-27T21:32:19.000Z", "I criticize parts of *both* the e/acc and EA camps for being too willing to put their trust in a single centralized actor, whether a nonprofit or a national government, in their solutions. https://t.co/rwalZlGSGv");
	await storage.addTweet("295218901", "1729251838581727232", "2023-11-27T21:32:20.000Z", "My philosophy: d/acc https://t.co/GDzrNrmQdz");
        const tx = await agent.runAgent("VitalikButerin");
        const res = await tx.wait();

	await oracle.addOpenAiResponse(0, 0, ['chatcmpl-9iEtr2rQUDJTHmgknueM6LCbpGmgE', 'Hello! How can I assist you today?', '', '', 1720330735, 'gpt-4-0125-preview', '', 'chat.completion', 10, 87, 97], '');

	console.log(await agent.getAgentRun(0));
	// const user = await storage.getUser("295218901");
	// expect(user).to.equal("VitalikButerin");
    });
});
