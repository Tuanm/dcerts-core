// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ContentPool.sol";

/** @title ContentPool with batching support. */
contract ContentPoolV2 is ContentPool {

    /** @dev The number of batches added. */
    uint totalBatches = 0;

    /** @dev Contains the batch's content identities. */
    mapping(uint => uint[]) batches;

    /** @dev Emitted when a batch is added. */
    event BatchAdded(address indexed author, uint batchId);

    /** @dev Emitted when a batch is locked. */
    event BatchLocked(address indexed author, uint batchId);

    /** @dev Emitted when a batch is unlocked. */
    event BatchUnlocked(address indexed author, uint batchId);

    /** @dev Retrieves a batch of contents by its identity. */
    function getBatch(uint _batchId) public view returns (Content[] memory) {
        require(_batchId < totalBatches, "Not found");
        uint[] memory contentIds = batches[_batchId];
        uint totalContents = contentIds.length;
        Content[] memory contents = new Content[](totalContents);
        for (uint index = 0; index < 1; index++) {
            contents[index] = get(contentIds[index]);
        }
        return contents;
    }

    /**
     * @dev Add a batch of contents.
     * @param _data contains first 8 bytes to define the length of each CID, the rest for storing CIDs.
     */
    function addBatch(bytes memory _data) public returns (uint) {
        uint batchStartsAt = 8;
        require(_data.length >= batchStartsAt, "Batch must provide CID length");
        uint batchId = totalBatches;
        // Get the defined length of each CID in first 8 bytes
        bytes memory cidLengthInBytes = new bytes(batchStartsAt);
        for (uint index = 0; index < batchStartsAt; index++) {
            cidLengthInBytes[index] = _data[index];
        }
        // Convert the 8 bytes to uint256
        uint cidLength;
        assembly {
            cidLength := mload(add(cidLengthInBytes, 0x20))
        }
        // Define the size of each cid before the cumulative process
        bytes memory cid = new bytes(cidLength);
        // Indicate the current vacancy of the cid
        uint cumulativeLength = 0;
        for (uint index = batchStartsAt; index < _data.length; index++) {
            // Each turn, a byte is added to the cid
            cid[cumulativeLength] = _data[index];
            // When the bytes reach the defined size, pass it into the `add` function
            if (++cumulativeLength == cidLength) {
                // Retrieve the identity of the content added
                uint id = add(cid);
                batches[batchId].push(id);
                cumulativeLength = 0;
            }
        }
        totalBatches = batchId + 1;
        emit BatchAdded(msg.sender, batchId);
        return batchId;
    }

    /** @dev Locks a batch of contents. */
    function lockBatch(bytes memory _data) public {
        uint batchId = parseBatchId(_data);
        uint[] memory contentIds = batches[batchId];
        uint totalContents = contentIds.length;
        for (uint index = 0; index < totalContents; index++) {
            lock(abi.encodePacked(contentIds[index]));
        }
        emit BatchLocked(msg.sender, batchId);
    }

    /** @dev Unlocks a locked batch of contents. */
    function unlockBatch(bytes memory _data) public {
        uint batchId = parseBatchId(_data);
        uint[] memory contentIds = batches[batchId];
        uint totalContents = contentIds.length;
        for (uint index = 0; index < totalContents; index++) {
            unlock(abi.encodePacked(contentIds[index]));
        }
        emit BatchUnlocked(msg.sender, batchId);
    }

    /** @dev Converts bytes data to a batch identity if it is available. */
    function parseBatchId(bytes memory _data) internal view returns (uint) {
        uint batchId;
        assembly {
            batchId := mload(add(_data, 0x20))
        }
        require(batchId < totalBatches, "Not found");
        return batchId;
    }
}