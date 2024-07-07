// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IOracle.sol";
import "hardhat/console.sol";

contract Storage {
    mapping(string => User) public usersById;
    mapping(string => string) public usersByLogin;

    struct User {
	string id;
	string login;
	bool isProcessing;
	Tweet[] tweets;
    }

    struct Tweet {
	string userId;
	string tweetId;
	string timestamp;
	string text;
    }

    function getUserByLogin(string memory login) public view returns (User memory) {
	return usersById[usersByLogin[login]];
    }

    function getTweet(string memory login, uint tweetId) public view returns (Tweet memory) {
	return usersById[usersByLogin[login]].tweets[tweetId];
    }

    function createUser(string memory id, string memory login) public {
        usersById[id] = User(id, login, false, new Tweet[](0));
        usersByLogin[login] = id;
    }

    function addTweet(string memory userId, string memory tweetId, string memory timestamp, string memory text) public {
	User storage user = usersById[userId];
        user.tweets.push(Tweet(userId, tweetId, timestamp, text));
    }
}
