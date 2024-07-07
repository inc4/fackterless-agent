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
	bool isBitcoin;
	bool isPrediction;
	bool isUp;
	string timeSpan;
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
	    _userIds.push(userId);
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
	Tweet storage tweet = usersById[usersByLogin[run.twitterLogin]].tweets[run.lastStorageId];

	string[] memory parts = split(response.content, "|");
	if (keccak256(abi.encodePacked(parts[0])) == keccak256(abi.encodePacked("1"))) {
	    tweet.isBitcoin = true;
	}
	if (keccak256(abi.encodePacked(parts[1])) == keccak256(abi.encodePacked("1"))) {
	    tweet.isPrediction = true;
	}
	if (keccak256(abi.encodePacked(parts[2])) == keccak256(abi.encodePacked("1"))) {
	    tweet.isUp = true;
	}
	tweet.timeSpan = parts[3];

	run.responses.push(response);
	run.errorMessage = errorMessage;
	run.iteration++;
    }

    function processTweet(uint runId) private {
	AgentRun storage run = agentRuns[runId];
	User storage user = usersById[usersByLogin[run.twitterLogin]];
	IStorage.Tweet memory tweet = IStorage(storageAddress).getTweet(run.twitterLogin, run.lastStorageId);
	user.tweets.push(Tweet(run.lastStorageId, tweet.userId, tweet.tweetId, false, false, false, "", false));
	string memory part1 =
	"Analyze the following tweet text and determine 4 parameters:\n"
	"1. Is it about Bitcoin? (about_bitcoin: true/false)\n"
	"2. Does the text contain a price prediction or? (is_prediction: true/false)\n"
	"3. If there is a prediction, does it imply a price increase? (up: true/false)\n"
	"4. Prediction duration. (time_span: seconds)\n"
	"\n"
	"Example tweet:\n"
	"\"I remember doing interviews about crypto in 2020 and asking people their bitcoin predictions. Bitcoin was at 8k at the time. One guy told me 40k this cycle. That number just blew my mind. At 8k it was impossible to comprehend those numbers. But we did it. Now when people say 200k for one bitcoin, I believe it.\"\n"
	"\n"
	"Response, contains \"about_bitcoin\",\"is_prediction\",\"up\",\"time_span\":\n"
	"true|true|true|259200\n"
	"\n"
	"Now analyze this tweet:\n";
        string memory code = string(abi.encodePacked(part1, tweet.text));
	run.messages.push(createTextMessage("user", code));
	IOracle(oracleAddress).createOpenAiLlmCall(agentCurrentId, config);
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

    function split(string memory _base, string memory _value) internal pure returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);
        uint _offset = 0;
        uint _splitsCount = 1;
        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == bytes(_value)[0]) {
                _splitsCount++;
            }
        }
        splitArr = new string[](_splitsCount);
        uint _splitIndex = 0;
        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == bytes(_value)[0]) {
                splitArr[_splitIndex] = substring(_base, _offset, i);
                _offset = i + 1;
                _splitIndex++;
            }
        }
        splitArr[_splitIndex] = substring(_base, _offset, _baseBytes.length);
        return splitArr;
    }

        function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}
