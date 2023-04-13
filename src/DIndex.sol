// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;
// import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// import "@semaphore-protocol/contracts/extensions/SemaphoreVoting.sol";

contract DIndex is Ownable {
    // CONSTANTS
    uint256 private constant RATING_DELAY = 4 weeks;
    uint256 private constant MULTIPLIER_PRECISION = 1e18;
    uint256 private constant MAX_ATTRIBUTES_AMOUNT = 20;

    // EVENTS
    event ProfileCreated(uint256 indexed indexId, string name, uint256 globalCummulativeRating, uint256 globalAverage);
    event AttributeAdded(
        uint256 indexed indexId,
        uint256 attributeId,
        string name,
        uint256 cummulativeRating,
        uint256 average,
        uint256 totalRatings
    );
    event IndexRated(
        uint256 indexed indexId,
        uint256 attributeIndex,
        uint256 attributeId,
        uint256 rating,
        uint256 lastRatingTime
    );

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
        // TODO: check if there is an index with the given name

        indices[currentIndexId].name = name;
        indices[currentIndexId].globalCumulativeRating = 0 * MULTIPLIER_PRECISION;
        indices[currentIndexId].globalAverage = 0 * MULTIPLIER_PRECISION;

        uint256 indexId = currentIndexId;
        currentIndexId += 1;

        emit ProfileCreated(indexId, name, 0, 0);

        return indexId;
    }

    // TODO check that sender is the creator of the index
    function addAttribute(uint256 indexId, uint256 attributeId, string memory name) external returns (bool) {
        require(bytes(indices[indexId].name).length > 0, "Index does not exists");
        require(bytes(name).length > 0, "Attribute name cannot be empty");
        
        Attribute[] memory attrs = indices[indexId].attributes;

        require(
            attrs.length < MAX_ATTRIBUTES_AMOUNT,
            string.concat("Max attributes items amount is ", Strings.toString(MAX_ATTRIBUTES_AMOUNT))
        );

        require(!findAttributeName(attrs, name), "Attribute with the given name already exists.");

        // TODO check attribute id
        indices[indexId].attributes.push(
            Attribute(attributeId, name, 0 * MULTIPLIER_PRECISION, 0 * MULTIPLIER_PRECISION, 0 * MULTIPLIER_PRECISION)
        );

        emit AttributeAdded(indexId, attributeId, name, 0, 0, 0);

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

        emit IndexRated(indexId, attributeIndex, attributeId, rating, block.timestamp + RATING_DELAY);

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

    // UTILS
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function findAttributeName(Attribute[] memory array, string memory _string) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            string memory stringToFind = array[i].name;
            bool exists = compareStrings(stringToFind, _string);

            if (exists == true) {
                return true;
            }
        }
        return false;
    }
}
