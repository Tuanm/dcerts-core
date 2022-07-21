// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/** @dev Content. */
struct Content {
    uint id;
    uint tag;
    uint timestamp;
    address author;
    bool locked;
    string cid;
}

/** @title Contains the contents. */
contract ContentPool {

    /** @dev Emitted when new content is added. */
    event ContentAdded(address indexed author, uint indexed id, uint indexed tag);

    /** @dev Emitted when a content is locked. */
    event ContentLocked(address indexed author, uint indexed id, uint indexed tag);

    /** @dev Emitted when a content is unlocked. */
    event ContentUnlocked(address indexed author, uint indexed id, uint indexed tag);

    /** @dev The number of contents added. */
    uint total = 0;

    /** @dev Contains all contents. */
    mapping(uint => Content) contents;

    /** @dev Returns the content with specific identity. */
    function get(uint _id) public view returns (Content memory) {
        require(_id < total, "Not found");
        Content memory content = contents[_id];
        require(!content.locked, "Content locked");
        return content;
    }

    /** @dev Adds new content. */
    function add(string memory _cid, uint _tag) public returns (uint) {
        uint id = total;
        contents[id] = Content({
            id: id,
            tag: _tag,
            timestamp: block.timestamp,
            author: msg.sender,
            locked: false,
            cid: _cid
        });
        total = id + 1;
        emit ContentAdded(msg.sender, id, _tag);
        return id;
    }

    /** @dev Locks a content. */
    function lock(uint _id) public {
        require(_id < total, "Not found");
        Content storage content = contents[_id];
        require(content.author == msg.sender, "No permission");
        content.locked = true;
        emit ContentLocked(msg.sender, _id, content.tag);
    }

    /** @dev Unlocks a locked content. */
    function unlock(uint _id) public {
        require(_id < total, "Not found");
        Content storage content = contents[_id];
        require(content.author == msg.sender, "No permission");
        content.locked = false;
        emit ContentUnlocked(msg.sender, _id, content.tag);
    }
}
