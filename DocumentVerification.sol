// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple e-Meterai / Document Stamp Registry (No Revoke)
contract DocumentStampRegistry {

    struct Document {
        string serial;      // nomor seri unik meterai
        string docType;     // jenis dokumen (misal: "KONTRAK", "INVOICE")
        address issuer;     // siapa yang menerbitkan
        uint256 issuedAt;   // kapan diterbitkan (timestamp)
        bool exists;        // penanda bahwa data pernah di-issue
    }

    // key = hash dokumen, value = data dokumen
    mapping(bytes32 => Document) public documents;

    // opsional: mapping dari serial → hash (biar bisa verify via serial)
    mapping(string => bytes32) public serialToHash;

    // admin penerbit (misal: PJAP / instansi resmi)
    address public owner;

    event DocumentIssued(
        bytes32 indexed docHash,
        string indexed serial,
        string docType,
        address indexed issuer,
        uint256 issuedAt
    );

    constructor() {
        owner = msg.sender; // yang deploy = otoritas penerbit awal
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /// Helper untuk hitung hash dari string (untuk testing / demo)
    function getHash(string calldata data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    /// Terbitkan dokumen dengan hash yang sudah dihitung di backend
    function issueDocument(
        bytes32 docHash,
        string calldata serial,
        string calldata docType
    ) external onlyOwner {
        require(!documents[docHash].exists, "Hash already issued");
        require(serialToHash[serial] == bytes32(0), "Serial already used");

        documents[docHash] = Document({
            serial: serial,
            docType: docType,
            issuer: msg.sender,
            issuedAt: block.timestamp,
            exists: true
        });

        serialToHash[serial] = docHash;

        emit DocumentIssued(docHash, serial, docType, msg.sender, block.timestamp);
    }

    /// Terbitkan dokumen langsung dari string (untuk demo/pengujian)
    function issueDocumentFromString(
        string calldata data,
        string calldata serial,
        string calldata docType
    ) external onlyOwner {
        bytes32 docHash = keccak256(abi.encodePacked(data));
        require(!documents[docHash].exists, "Hash already issued");
        require(serialToHash[serial] == bytes32(0), "Serial already used");

        documents[docHash] = Document({
            serial: serial,
            docType: docType,
            issuer: msg.sender,
            issuedAt: block.timestamp,
            exists: true
        });

        serialToHash[serial] = docHash;

        emit DocumentIssued(docHash, serial, docType, msg.sender, block.timestamp);
    }

    /// Verifikasi berdasarkan hash dokumen
    function verifyByHash(bytes32 docHash)
        external
        view
        returns (
            bool found,
            string memory serial,
            string memory docType,
            address issuer,
            uint256 issuedAt
        )
    {
        Document memory doc = documents[docHash];
        if (!doc.exists) {
            return (false, "", "", address(0), 0);
        }
        return (true, doc.serial, doc.docType, doc.issuer, doc.issuedAt);
    }

    /// Verifikasi berdasarkan serial number
    function verifyBySerial(string calldata serial)
        external
        view
        returns (
            bool found,
            bytes32 docHash,
            string memory docType,
            address issuer,
            uint256 issuedAt
        )
    {
        bytes32 hash = serialToHash[serial];
        if (hash == bytes32(0)) {
            return (false, bytes32(0), "", address(0), 0);
        }

        Document memory doc = documents[hash];
        return (true, hash, doc.docType, doc.issuer, doc.issuedAt);
    }
}
