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
        const { agent, oracle, storage, owner } = await loadFixture(deploy);
        const login = "VitalikButerin";

        await storage.createUser("295218901", login);

        await storage.addTweet("295218901", "1729251834404249696", "2023-11-27T21:32:19.000Z", "I criticize parts of *both* the e/acc and EA camps for being too willing to put their trust in a single centralized actor, whether a nonprofit or a national government, in their solutions. https://t.co/rwalZlGSGv");
        await storage.addTweet("295218901", "1729251838581727232", "2023-11-27T21:32:20.000Z", "My philosophy: d/acc https://t.co/GDzrNrmQdz");

        let iteration = 0;

        const tx = await agent.runAgent(login);
        const res = await tx.wait();
        const id = res.logs[1].args[0];


        // Step 1
        let run = await agent.getAgentRun(id);
        expect(run.iteration).to.equal(iteration + 1);
        expect(run.isFinished).to.equal(true);
        await oracle.addOpenAiResponse(id, iteration, ['chatcmpl-9iEtr2rQUDJTHmgknueM6LCbpGmgE', '{"about_bitcoin": "true","is_prediction": "true","up": "true"}', '', '', 1720330735, 'gpt-4-0125-preview', '', 'chat.completion', 10, 87, 97], '');
        // await oracle.addScriptResponse(id, iteration, '{"isCorrect": "true"}', '');

        let user = await storage.getUserByLogin(login);
        let tweets = await agent.user.tweets(user.id);
        expect(tweets[iteration].userId).to.equal(user.id);
        expect(tweets[iteration].tweetId).to.equal("1729251834404249696");
        expect(tweets[iteration].isCorrect).to.equal(true);
        iteration++;

        // Step 2
        run = await agent.getAgentRun(id);
        expect(run.iteration).to.equal(iteration + 1);
        expect(run.isFinished).to.equal(true);

        await oracle.addOpenAiResponse(id, iteration, ['chatcmpl-9iEtr2rQUDJTHmgknueM6LCbpGmgE', '{"about_bitcoin": "true","is_prediction": "true","up": "true"}', '', '', 1720330735, 'gpt-4-0125-preview', '', 'chat.completion', 10, 87, 97], '');
        // await oracle.addScriptResponse(id, iteration, '{"isCorrect": "true"}', '');

        user = await storage.getUserByLogin(login);
        tweets = await agent.user.tweets(user.id);
        expect(tweets[iteration].userId).to.equal(user.id);
        expect(tweets[iteration].tweetId).to.equal("1729251834404249696");
        expect(tweets[iteration].isCorrect).to.equal(true);
        iteration++;


    });

});
