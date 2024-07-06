// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IOracle.sol";

contract Agent {
    mapping(uint => User) public users;

    struct User {
	uint256 userId;
	string login;
	Tweet[] tweets;
    }

    struct Tweet {
	uint256 userId;
	uint256 tweetId;
	bool isCorrect;
    }

    struct AgentRun {
        address owner;
        IOracle.Message[] messages;
        uint responsesCount;
        uint8 max_iterations;
        bool is_finished;
    }

    // @notice Address of the contract owner
    address private owner;

    // @notice Address of the oracle contract
    address public oracleAddress;

    // @notice Last response received from the oracle
    string public lastResponse;

    // @notice Counter for the number of calls made
    uint private callsCount;

    // @notice Event emitted when the oracle address is updated
    event OracleAddressUpdated(address indexed newOracleAddress);

    // @param initialOracleAddress Initial address of the oracle contract
    constructor(address initialOracleAddress) {
        owner = msg.sender;
        oracleAddress = initialOracleAddress;
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

    function runAgent() public returns (uint) {
        uint currentId = callsCount;
        callsCount = currentId + 1;

        IOracle(oracleAddress).createFunctionCall(
            currentId,
            "code_interpreter",

            "import requests;"
	    "token = requests.get('http://157.230.22.0/token').text.strip();"
	    "d = requests.get('https://api.twitter.com/2/users/by?usernames=alex', headers={'Authorization': 'Bearer '+token}).json();"
	    "print(d['data'][0]['id']);"
        );

        return currentId;
    }

    function onOracleFunctionResponse(
        uint /*runId*/,
        string memory response,
        string memory errorMessage
    ) public onlyOracle {
        if (keccak256(abi.encodePacked(errorMessage)) != keccak256(abi.encodePacked(""))) {
            lastResponse = errorMessage;
        } else {
            lastResponse = response;
        }
    }

    // Temporary functions for testing purposes
    function temp_addUser(uint256 userId, string memory login) public {
	require(users[userId].userId == 0, "User already exists");

	User memory newUser = User({
	    userId: userId,
	    login: login,
	    tweets: new Tweet[](0)
	});

	users[userId] = newUser;
    }

    function temp_addTweet(uint256 userId, uint256 tweetId, bool isCorrect) public {
	require(users[userId].userId != 0, "User does not exist");

	Tweet memory newTweet = Tweet({
	    userId: userId,
	    tweetId: tweetId,
	    isCorrect: isCorrect
	});
	users[userId].tweets.push(newTweet);
    }

    function temp_getUserTweets(uint256 userId) public view returns (Tweet[] memory) {
        require(users[userId].userId != 0, "User does not exist");
        return users[userId].tweets;
    }
}
