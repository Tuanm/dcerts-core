// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/** @dev Content. */
struct Content {
    uint id;
    uint timestamp;
    address author;
    bool locked;
    string cid;
}

/** @title Contains the contents. */
contract ContentPool {

    /** @dev Emitted when new content is added. */
    event ContentAdded(address indexed author, uint indexed id, string indexed cid);

    /** @dev Emitted when a content is locked. */
    event ContentLocked(address indexed author, uint indexed id);

    /** @dev Emitted when a content is unlocked. */
    event ContentUnlocked(address indexed author, uint indexed id);

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
    function add(bytes memory _data) public returns (uint) {
        uint id = total;
        string memory cid = string(_data);
        contents[id] = Content({
            id: id,
            timestamp: block.timestamp,
            author: msg.sender,
            locked: false,
            cid: cid
        });
        total = id + 1;
        emit ContentAdded(msg.sender, id, cid);
        return id;
    }

    /** @dev Locks a content. */
    function lock(bytes memory _data) public {
        uint id = parseId(_data);
        Content storage content = contents[id];
        require(content.author == msg.sender, "No permission");
        content.locked = true;
        emit ContentLocked(msg.sender, id);
    }

    /** @dev Unlocks a locked content. */
    function unlock(bytes memory _data) public {
        uint id = parseId(_data);
        Content storage content = contents[id];
        require(content.author == msg.sender, "No permission");
        content.locked = false;
        emit ContentUnlocked(msg.sender, id);
    }

    /** @dev Converts bytes data to a content identity if it is available. */
    function parseId(bytes memory _data) internal view returns (uint) {
        uint id;
        assembly {
            id := mload(add(_data, 0x20))
        }
        require(id < total, "Not found");
        return id;
    }
}
