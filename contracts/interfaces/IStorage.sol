// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IStorage {
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

    function getUserByLogin(string memory login) external view returns (User memory);
    function getTweet(string memory userId, uint tweetId) external view returns (Tweet memory);
}
