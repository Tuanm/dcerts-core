// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/** @dev A certificate. */
struct Cert {
    uint id;
    uint timestamp;
    address issuer;
    bool locked;
    string cid;
}

/** @title Contains the certificates. */
contract CertPool {

    /** @dev Emitted when new certificate is added. */
    event CertAdded(uint indexed id, string cid);

    /** @dev Emitted when a certificate is locked. */
    event CertLocked(uint indexed id);

    /** @dev Emitted when a certificate is unlocked. */
    event CertUnlocked(uint indexed id);

    /** @dev The number of certificates added. */
    uint total = 0;

    /** @dev Contains all certificates. */
    mapping(uint => Cert) certs;

    /** @dev Returns the certificate with specific identity. */
    function get(uint _id) public view returns (Cert memory) {
        require(_id < total, "Not found");
        Cert memory cert = certs[_id];
        require(!cert.locked, "Certificate locked");
        return cert;
    }

    /** @dev Adds new certificate. */
    function add(bytes memory _data) public returns (uint) {
        uint id = total;
        string memory cid = string(_data);
        certs[id] = Cert({
            id: id,
            timestamp: block.timestamp,
            issuer: msg.sender,
            locked: false,
            cid: cid
        });
        total = id + 1;
        emit CertAdded(id, cid);
        return id;
    }

    /** @dev Locks a certificate. */
    function lock(bytes memory _data) public {
        uint id = parseId(_data);
        Cert storage cert = certs[id];
        require(cert.issuer == msg.sender, "No permission");
        cert.locked = true;
        emit CertLocked(id);
    }

    /** @dev Unlocks a locked certificate. */
    function unlock(bytes memory _data) public {
        uint id = parseId(_data);
        Cert storage cert = certs[id];
        require(cert.issuer == msg.sender, "No permission");
        cert.locked = false;
        emit CertUnlocked(id);
    }

    /** @dev Converts bytes data to a certificate identity if it is available. */
    function parseId(bytes memory _data) internal view returns (uint) {
        uint id;
        assembly {
            id := mload(add(_data, 0x20))
        }
        require(id < total, "Not found");
        return id;
    }
}
