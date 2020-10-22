// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

library SafeUint8 {
    /// @notice Adds two uint8 integers and fails if an overflow occurs
    function add8(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "overflow");

        return c;
    }
}

/// @notice The `IProcessStore` interface allows different versions of the contract to talk to each other. Not all methods in the contract need to be future proof.
/// @notice Should operations be updated, then two versions should be kept, one for the old version and one for the new.
interface IProcessStore {
    using SafeUint8 for uint8;
    
    enum Status {READY, ENDED, CANCELED, PAUSED, RESULTS}

    struct ProcessResults {
        uint32[][] tally;     // apperence count for every question and option value
        uint32 height;        // total number of votes of the process
        bytes32[] signatures; // signatures agreeing on the results published
        bytes[] proofs;       // proofs for verifing the results published
    }

    modifier onlyContractOwner virtual;
    modifier onlyIfActive virtual;
    modifier onlyOracle(bytes32 processId) virtual;

    // GET
    function getEntityProcessCount(address entityAddress) external view returns (uint256);
    function getNextProcessId(address entityAddress, uint16 namespace) external view returns (bytes32);
    function getProcessId(address entityAddress, uint256 processCountIndex, uint16 namespace) external pure returns (bytes32);
    function activate() external;
    function activateSuccessor(address successor) external;
    function get(bytes32 processId) external view returns (
        uint8[2] memory mode_envelopeType,
        address entityAddress,
        string[3] memory metadata_censusMerkleRoot_censusMerkleTree,
        uint64 startBlock,
        uint32 blockCount,
        Status status,
        uint8[5] memory questionIndex_questionCount_maxCount_maxValue_maxVoteOverwrites,
        bool uniqueValues,
        uint16[3] memory maxTotalCost_costExponent_namespace
    );
    function getParamsSignature(bytes32 processId) external view returns (bytes32);
    function getResults(bytes32 processId) external view returns (ProcessResults memory results);
    function getCreationInstance(bytes32 processId) external view returns (address);

    // SET
    function newProcess(
        uint8[2] memory mode_envelopeType,
        string[3] memory metadata_merkleRoot_merkleTree,
        uint64 startBlock,
        uint32 blockCount,
        uint8[4] memory questionCount_maxCount_maxValue_maxVoteOverwrites,
        bool uniqueValues,
        uint16[2] memory maxTotalCost_costExponent,
        uint16 namespace,
        bytes32 paramsSignature
    ) external;
    function setStatus(bytes32 processId, Status newStatus) external;
    function incrementQuestionIndex(bytes32 processId) external;
    function setCensus(bytes32 processId, string memory censusMerkleRoot, string memory censusMerkleTree) external;
    function setResults(bytes32 processId, uint32[][] memory tally, uint32 height, bytes32 signature, bytes memory proof) external;
    function addResultsSignature(bytes32 processId, bytes32 signature) external;
    function addResultsProof(bytes32 processId, bytes memory proof) external;

    // EVENTS
    event Activated(uint blockNumber);
    event ActivatedSuccessor(uint blockNumber, address successor);
    event NewProcess(bytes32 processId, uint16 namespace);
    event StatusUpdated(bytes32 processId, uint16 namespace, Status status);
    event QuestionIndexUpdated(
        bytes32 processId,
        uint16 namespace,
        uint8 newIndex
    );
    event CensusUpdated(bytes32 processId, uint16 namespace);
    event ResultsAvailable(bytes32 processId);
    event ResultsSignatureAdded(bytes32 processId, address oracle);
    event ResultsProofAdded(bytes32 processId, address oracle);
}

/// @notice The `INamespaceStore` interface defines the standard methods that allow querying and updating the details of each namespace.
interface INamespaceStore {
    modifier onlyContractOwner virtual;

    // SETTERS
    function setNamespace(uint16 namespace, string memory chainId, string memory genesis, string[] memory validators, address[] memory oracles) external;
    function setChainId(uint16 namespace, string memory newChainId) external;
    function setGenesis(uint16 namespace, string memory newGenesis) external;
    function addValidator(uint16 namespace, string memory validatorPublicKey) external;
    function removeValidator(uint16 namespace, uint256 idx, string memory validatorPublicKey) external;
    function addOracle(uint16 namespace, address oracleAddress) external;
    function removeOracle(uint16 namespace, uint256 idx, address oracleAddress) external;

    // GETTERS
    function getNamespace(uint16 namespace) external view returns (string memory chainId, string memory genesis, string[] memory validators, address[] memory oracles);
    function isValidator(uint16 namespace, string memory validatorPublicKey) external view returns (bool);
    function isOracle(uint16 namespace, address oracleAddress) external view returns (bool);

    // EVENTS
    event NamespaceUpdated(uint16 namespace);
    event ChainIdUpdated(string chainId, uint16 namespace);
    event GenesisUpdated(string genesis, uint16 namespace);
    event ValidatorAdded(string validatorPublicKey, uint16 namespace);
    event ValidatorRemoved(string validatorPublicKey, uint16 namespace);
    event OracleAdded(address oracleAddress, uint16 namespace);
    event OracleRemoved(address oracleAddress, uint16 namespace);
}
