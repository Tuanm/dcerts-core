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
    event CertAdded(uint id, string cid);

    /** @dev Emitted when a certificate is locked. */
    event CertLocked(uint id);

    /** @dev Emitted when a certificate is unlocked. */
    event CertUnlocked(uint id);

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
    function add(bytes memory _data) public {
        uint id = total;
        string memory cid;
        assembly {
            cid := mload(_data)
        }
        certs[id] = Cert({
            id: id,
            timestamp: block.timestamp,
            issuer: msg.sender,
            locked: false,
            cid: cid
        });
        total = id + 1;
        emit CertAdded(id, cid);
    }

    /** @dev Locks a certificate. */
    function lock(bytes memory _data) public {
        uint id;
        assembly {
            id := mload(_data)
        }
        require(id < total, "Not found");
        Cert memory cert = certs[id];
        require(cert.issuer == msg.sender, "No permission");
        cert.locked = true;
        emit CertLocked(id);
    }

    /** @dev Unlocks a certificate. */
    function unlock(bytes memory _data) public {
        uint id;
        assembly {
            id := mload(_data)
        }
        require(id < total, "Not found");
        Cert memory cert = certs[id];
        require(cert.issuer == msg.sender, "No permission");
        cert.locked = false;
        emit CertUnlocked(id);
    }
}
