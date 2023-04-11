// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;
// import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "@semaphore-protocol/contracts/extensions/SemaphoreVoting.sol";

contract DIndex is Ownable {
    // CONSTANTS
    uint256 private constant RATING_DELAY = 4 weeks;
    uint256 private constant MULTIPLIER_PRECISION = 1e18;

    // TODO: events
    event ProfileCreated(uint256 indexed indexId, string name);
    event AttributeAdded(uint256 indexed indexId, uint256 attributeId);
    event IndexRated(uint256 indexed indexId, uint256 attributeIndex, uint256 rating);

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

    struct Index {
        string name;
        Attribute[] attributes;
        // qualifier -> attribute id -> Rating
        mapping(address => mapping(uint256 => Rating)) ratings;
        uint256 globalCumulativeRating;
        uint256 globalAverage;
    }

    // variables
    uint256 private currentIndexId = 0;
    mapping(uint256 => Index) public indices;

    function createIndexProfile(string memory name) external onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");

        indices[currentIndexId].name = name;
        indices[currentIndexId].globalCumulativeRating = 0 * MULTIPLIER_PRECISION;
        indices[currentIndexId].globalAverage = 0 * MULTIPLIER_PRECISION;

        uint256 indexId = currentIndexId;
        currentIndexId += 1;

        // TODO: emit
        emit ProfileCreated(indexId, name);

        return indexId;
    }

    function addAttribute(uint256 indexId, uint256 attributeId, string memory name) external returns (bool) {
        require(bytes(indices[indexId].name).length > 0, "Index does not exists");
        require(bytes(name).length > 0, "Attribute name cannot be empty");

        // TODO check attribute id
        indices[indexId].attributes.push(
            Attribute(attributeId, name, 0 * MULTIPLIER_PRECISION, 0 * MULTIPLIER_PRECISION, 0 * MULTIPLIER_PRECISION)
        );

        // TODO: emit event
        emit AttributeAdded(indexId, attributeId);

        return true;
    }

    function rateIndex(uint256 indexId, uint256 attributeIndex, uint256 rating) external returns (uint256 average) {
        uint256 attributeId = indices[indexId].attributes[attributeIndex].attributeId;

        require(bytes(indices[indexId].name).length > 0, "Index does not exists");
        require(bytes(indices[indexId].attributes[attributeIndex].name).length > 0, "Attribute does not exists!");
        require(rating > 0, "Rating cannot be zero");
        require(rating <= 10, "The max rating is 10");
        require(
            block.timestamp >= indices[indexId].ratings[msg.sender][attributeId].lastRatingTime,
            "Cannot rate so often"
        );

        indices[indexId].globalCumulativeRating += rating * MULTIPLIER_PRECISION;
        indices[indexId].globalAverage = indices[indexId].globalCumulativeRating / indices[indexId].attributes.length;

        indices[indexId].ratings[msg.sender][attributeId].lastRatingTime = block.timestamp + RATING_DELAY;
        indices[indexId].ratings[msg.sender][attributeId].qualifier = msg.sender;
        indices[indexId].ratings[msg.sender][attributeId].rating = rating;
        indices[indexId].ratings[msg.sender][attributeId].attributeId = attributeId;

        indices[indexId].attributes[attributeIndex].totalRatings += 1;
        indices[indexId].attributes[attributeIndex].cumulativeRating += rating;
        indices[indexId].attributes[attributeIndex].average =
            (indices[indexId].attributes[attributeIndex].cumulativeRating * MULTIPLIER_PRECISION) /
            indices[indexId].attributes[attributeIndex].totalRatings;

        // TODO: emit
        emit IndexRated(indexId, attributeIndex, rating);

        return indices[indexId].globalAverage;
    }

    function getIndexAverage(uint256 indexId) external view returns (uint256) {
        return indices[indexId].globalAverage;
    }

    function getAttributeAverage(uint256 indexId, uint256 attributeIndex) external view returns (uint256) {
        return indices[indexId].attributes[attributeIndex].average;
    }

    function getIndexAttributes(uint256 indexId) external view returns (Attribute[] memory attributes) {
        return indices[indexId].attributes;
    }
}
