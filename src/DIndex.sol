// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";

contract DIndex {
    event NewRate(bytes32 _rate);
    event NewUser(uint256 identityCommitment, bytes32 username);
    // solhint-disable-previous-line no-empty-blocks
    ISemaphore public semaphore;
    uint256 private groupId;
    mapping(uint256 => bytes32) private users;

    constructor(address semaphoreAddress, uint256 _groupId) {
        semaphore = ISemaphore(semaphoreAddress);
        groupId = _groupId;

        semaphore.createGroup(groupId, 20, 0, address(this));
    }

    function joinGroup(uint256 identityCommitment, bytes32 username) external {
        semaphore.addMember(groupId, identityCommitment);

        users[identityCommitment] = username;

        emit NewUser(identityCommitment, username);
    }

    function rate(
        bytes32 _rate,
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        semaphore.verifyProof(groupId, merkleTreeRoot, _rate, nullifierHash, groupId, proof);

        emit NewRate(_rate);
    }
}
