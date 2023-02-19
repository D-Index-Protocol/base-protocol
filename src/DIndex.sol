// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;
// import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "@semaphore-protocol/contracts/extensions/SemaphoreVoting.sol";

contract DIndex is Ownable {
    // CONSTANTS
    uint256 private constant RATING_DELAY = 4 weeks;
    // STRUCTS
    struct Attribute {
        uint256 attributeId;
        string name;
        uint256 cumulativeRating;
        uint256 average;
        uint256 totalRatings;
    }

    struct Rating {
        address qualifier;
        uint256 rating;
        uint256 attributeId;
        uint256 lastRatingTime;
    }

    struct Dapp {
        string name;
        Attribute[] attributes;
        // qualifier -> attribute id -> Rating
        mapping(address => mapping(uint256 => Rating)) ratings;
        uint256 globalCumulativeRating;
        uint256 globalAverage;
        address qualifier;
    }

    // variables
    uint256 private currentDappId = 0;
    mapping(uint256 => Dapp) public dapps;

    function createDappProfile(string memory name) external onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");

        dapps[currentDappId].name = name;
        dapps[currentDappId].globalCumulativeRating = 0;
        dapps[currentDappId].globalAverage = 0;

        uint256 dappId = currentDappId;
        currentDappId += 1;

        return dappId;
    }

    function addAttribute(
        uint256 dappId,
        uint256 attributeId,
        string memory name
    ) external returns (bool) {
        require(bytes(dapps[dappId].name).length > 0, "Dapp does not exists");
        require(bytes(name).length > 0, "Attribute name cannot be empty");

        dapps[dappId].attributes.push(Attribute(attributeId, name, 0, 0, 0));

        return true;
    }

    function rateDapp(
        uint256 dappId,
        uint256 attributeIndex,
        uint256 rating
    ) external returns (uint256 average) {
        uint256 attributeId = dapps[dappId].attributes[attributeIndex].attributeId;

        require(bytes(dapps[dappId].name).length > 0, "Dapp does not exists");
        require(bytes(dapps[dappId].attributes[attributeIndex].name).length > 0, "Attribute does not exists!");
        require(rating > 0, "Rating cannot be zero");
        require(rating <= 10, "The max rating is 10");
        require(
            block.timestamp >= dapps[dappId].ratings[msg.sender][attributeId].lastRatingTime,
            "Cannot rate so often"
        );

        dapps[dappId].globalCumulativeRating += rating;
        dapps[dappId].globalAverage = dapps[dappId].globalCumulativeRating / dapps[dappId].attributes.length;

        dapps[dappId].ratings[msg.sender][attributeId].lastRatingTime = block.timestamp + RATING_DELAY;
        dapps[dappId].ratings[msg.sender][attributeId].qualifier = msg.sender;
        dapps[dappId].ratings[msg.sender][attributeId].rating = rating;
        dapps[dappId].ratings[msg.sender][attributeId].attributeId = attributeId;

        dapps[dappId].attributes[attributeIndex].totalRatings += 1;
        dapps[dappId].attributes[attributeIndex].cumulativeRating += rating;
        dapps[dappId].attributes[attributeIndex].average =
            dapps[dappId].attributes[attributeIndex].cumulativeRating /
            dapps[dappId].attributes[attributeIndex].totalRatings;

        return dapps[dappId].globalAverage;
    }

    function getDappAverage(uint256 dappId) external returns (uint256) {
        return dapps[dappId].globalAverage;
    }

    function getAttributeAverage(uint256 dappId, uint256 attributeIndex) external returns (uint256) {
        return dapps[dappId].attributes[attributeIndex].average;
    }

    function getDappAttributes(uint256 dappId) external returns (Attribute[] memory attributes) {
        return dapps[dappId].attributes;
    }
}
