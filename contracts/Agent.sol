// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IOracle.sol";
import "./interfaces/IStorage.sol";
import "hardhat/console.sol";

contract Agent {
    string[] public _userIds;
    mapping(string => User) public usersById;
    mapping(string => string) public usersByLogin;

    struct User {
	string login;
	string userId;
	Tweet[] tweets;
    }

    struct Tweet {
	uint storageId;
	string userId;
	string tweetId;
	bool isCorrect;
    }

    uint private agentCurrentId;
    mapping(uint => AgentRun) public agentRuns;
    struct AgentRun {
        address owner;
	IOracle.Message[] messages;
	string twitterLogin;
	uint lastStorageId;
	string[] codeInterpreted;
	IOracle.OpenAiResponse[] responses;
        string errorMessage;
        uint iteration;
        bool isFinished;
    }

    // @notice Address of the contract owner
    address private owner;

    // @notice Address of the oracle contract
    address public oracleAddress;

    // @notice Address of the storage contract
    address public storageAddress;

    IOracle.OpenAiRequest private config;

    // @notice Event emitted when the oracle address is updated
    event OracleAddressUpdated(address indexed newOracleAddress);

    event RunCreated(uint256 indexed runId, address indexed owner);

    // @param initialOracleAddress Initial address of the oracle contract
    constructor(address initialOracleAddress, address initialStorageAddress) {
        owner = msg.sender;
        oracleAddress = initialOracleAddress;
	storageAddress = initialStorageAddress;
	config = IOracle.OpenAiRequest({
            model : "gpt-4-turbo-preview",
            frequencyPenalty : 21, // > 20 for null
            logitBias : "", // empty str for null
            maxTokens : 1000, // 0 for null
            presencePenalty : 21, // > 20 for null
            responseFormat : "{\"type\":\"text\"}",
            seed : 0, // null
            stop : "", // null
            temperature : 10, // Example temperature (scaled up, 10 means 1.0), > 20 means null
            topP : 101, // Percentage 0-100, > 100 means null
            tools : "[{\"type\":\"function\",\"function\":{\"name\":\"web_search\",\"description\":\"Search the internet\",\"parameters\":{\"type\":\"object\",\"properties\":{\"query\":{\"type\":\"string\",\"description\":\"Search query\"}},\"required\":[\"query\"]}}},{\"type\":\"function\",\"function\":{\"name\":\"image_generation\",\"description\":\"Generates an image using Dalle-2\",\"parameters\":{\"type\":\"object\",\"properties\":{\"prompt\":{\"type\":\"string\",\"description\":\"Dalle-2 prompt to generate an image\"}},\"required\":[\"prompt\"]}}}]",
            toolChoice : "auto", // "none" or "auto"
            user : "" // null
        });
    }

    // @notice Ensures the caller is the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    // @notice Ensures the caller is the oracle contract
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not oracle");
        _;
    }

    // @notice Updates the oracle address
    // @param newOracleAddress The new oracle address to set
    function setOracleAddress(address newOracleAddress) public onlyOwner {
        oracleAddress = newOracleAddress;
        emit OracleAddressUpdated(newOracleAddress);
    }

    // @notice Updates the storage address
    // @param newStorageAddress The new storage address to set
    function setStorageAddress(address newStorageAddress) public onlyOwner {
        storageAddress = newStorageAddress;
    }

    function runAgent(string memory twitterLogin) public returns (uint) {
        AgentRun storage run = agentRuns[agentCurrentId];

        run.owner = msg.sender;
        run.twitterLogin = twitterLogin;

        uint runId = agentCurrentId;
        agentCurrentId++;

	string memory userId = usersByLogin[twitterLogin];
	if (keccak256(abi.encodePacked(userId)) == keccak256(abi.encodePacked(""))) {
	    IStorage.User memory u = IStorage(storageAddress).getUserByLogin(twitterLogin);
	    userId = u.id;
	    usersById[u.id] = User(twitterLogin, userId, new Tweet[](0));
	    usersByLogin[twitterLogin] = userId;
	    run.lastStorageId = 0;
	}
	processTweet(runId);

	emit RunCreated(runId, msg.sender);
        return runId;
    }

    function onOracleOpenAiLlmResponse(
        uint runId,
        IOracle.OpenAiResponse memory response,
        string memory errorMessage
    ) public onlyOracle {
	AgentRun storage run = agentRuns[runId];

	run.responses.push(response);
	run.errorMessage = errorMessage;
	run.iteration++;
    }

    function processTweet(uint runId) private {
	AgentRun storage run = agentRuns[runId];
	// IStorage.Tweet memory tweet = IStorage(storageAddress).getTweet(run.twitterLogin, run.lastStorageId);
	// TODO
	run.messages.push(createTextMessage("user", "Hello, world!"));
	IOracle(oracleAddress).createOpenAiLlmCall(runId, config);
    }

    function getMessageHistory(
        uint runId
    ) public view returns (IOracle.Message[] memory) {
	return agentRuns[runId].messages;
    }

    function createTextMessage(string memory role, string memory content) private pure returns (IOracle.Message memory) {
        IOracle.Message memory newMessage = IOracle.Message({
            role: role,
            content: new IOracle.Content[](1)
        });
        newMessage.content[0].contentType = "text";
        newMessage.content[0].value = content;
        return newMessage;
    }

    function getAgentRun(uint runId) public view returns (AgentRun memory) {
	return agentRuns[runId];
    }

    function user(string memory userId) public view returns (User memory) {
	return usersById[userId];
    }

    function userIds() public view returns (string[] memory) {
        return _userIds;
    }
}
