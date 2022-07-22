// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ContentPool.sol";

struct ContentHeader {
    string cid;
    uint tag;
}

/** @title ContentPool with batching support. */
contract ContentPoolV2 is ContentPool {

    /** @dev The number of batches added. */
    uint totalBatches = 0;

    /** @dev Contains the batch's content identities. */
    mapping(uint => uint[]) batches;

    /** @dev Emitted when a batch is added. */
    event BatchAdded(address indexed author, uint indexed batchId, uint indexed contentId);

    /** @dev Emitted when a batch is locked. */
    event BatchLocked(address indexed author, uint indexed batchId, uint indexed contentId);

    /** @dev Emitted when a batch is unlocked. */
    event BatchUnlocked(address indexed author, uint indexed batchId, uint indexed contentId);

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

    /** @dev Add a batch of contents. */
    function addBatch(ContentHeader[] calldata _headers) public returns (uint) {
        uint batchId = totalBatches;
        for (uint index = 0; index < _headers.length; index++) {
            ContentHeader calldata header = _headers[index];
            uint contentId = add(header.cid, header.tag);
            batches[batchId].push(contentId);
            emit BatchAdded(msg.sender, batchId, contentId);
        }
        totalBatches = batchId + 1;
        return batchId;
    }

    /** @dev Locks a batch of contents. */
    function lockBatch(uint _batchId) public {
        require(_batchId < totalBatches, "Not found");
        uint[] memory contentIds = batches[_batchId];
        uint totalContents = contentIds.length;
        for (uint index = 0; index < totalContents; index++) {
            uint contentId = contentIds[index];
            lock(contentId);
            emit BatchLocked(msg.sender, _batchId, contentId);
        }
    }

    /** @dev Unlocks a locked batch of contents. */
    function unlockBatch(uint _batchId) public {
        require(_batchId < totalBatches, "Not found");
        uint[] memory contentIds = batches[_batchId];
        uint totalContents = contentIds.length;
        for (uint index = 0; index < totalContents; index++) {
            uint contentId = contentIds[index];
            unlock(contentId);
            emit BatchUnlocked(msg.sender, _batchId, contentId);
        }
    }
}