// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.7.0;

import "./openzeppelin/token/ERC20/IERC20.sol";
import "./rlp/RLPReader.sol";
import "./lib.sol";

contract ERC20StorageProof {
    
    using TrieProofs for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;

    event TokenRegistered(address indexed token, address indexed registrar);
    
    struct ERC20Token {
        bool registered;
        uint256 balanceMappingPosition;
    }

    mapping(address => ERC20Token) public tokens;

    function isRegistered(address ercTokenAddress) public view returns (bool) {
        require(ercTokenAddress != address(0x0));
        return tokens[ercTokenAddress].registered;
    }

    function register(
        address tokenAddress,
        uint256 balanceMappingPosition,
        uint256 blockNumber,
        bytes memory blockHeaderRLP,
        bytes memory accountStateProof,
        bytes memory storageProof
    ) public {
        // Check that the address is a contract
        require(
            ContractSupport.isContract(tokenAddress),
            "The address must be a contract"
        );

        // check token is not registered
        require(!isRegistered(tokenAddress), "Token already registered");

        // check msg.sender balance calling 'balanceOf' function on the ERC20 contract
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 balance = tokenContract.balanceOf(msg.sender);
        require(balance > 0, "Insufficient funds");

        // check storage root hash valid for height
        // check storage proof valid for balanceMappingPosition (value returned == balance)
        uint256 balanceFromTrie = 0; 
        balanceFromTrie = getBalance(tokenAddress, msg.sender, blockNumber, blockHeaderRLP, accountStateProof, storageProof, balanceMappingPosition);
        
        require(balanceFromTrie > 0, "Insufficient funds, proof verification failed");
        ERC20Token storage newToken;
        newToken.registered = true;
        newToken.balanceMappingPosition = balanceMappingPosition;
        tokens[tokenAddress] = newToken;

        emit TokenRegistered(token, registar);
    }

    function getStorageRoot(
        address account,
        uint256 blockNumber,
        bytes memory blockHeaderRLP,
        bytes memory accountStateProof
    ) public {
        // Slots 0...256 store the most recent 256 block hashes are available
        // Slots 256...511 store the most recent 256 blockhashes where blocknumber % 256 == 0
        // Slots 512...767 store the most recent 256 blockhashes where blocknumber % 65536 == 0 
        bytes32 blockHash = blockhash(blockNumber);
        require(blockHash != bytes32(0), "blockhash not available");
        // get the state root from the RLP encoded block header and verify
        bytes32 stateRoot = getBlockHeaderStateRoot(blockHeaderRLP, blockHash);
        // The path for an account in the state trie is the hash of its address
        bytes32 proofPath = keccak256(abi.encodePacked(account));
        // Get the account state from a merkle proof in the state trie. Returns an RLP encoded bytes array
        bytes memory accountRLP = TrieProofs.verify(accountStatePRoof, stateRoot, proofPath); // reverts if proof is invalid
        // Extract the storage root from the account node and convert to bytes32
        return bytes32(accountRLP.toRLPItem().toList()[ACCOUNT_STORAGE_ROOT_INDEX].toUint());
    }

    function getStorage(
        address account,
        uint256 blockNumber,
        uint256 slot,
        bytes32 stateRoot,
        bytes memory storageProof
    ) public view returns (uint256) {
        require(stateRoot != bytes32(0), "no data");

        // The path for a storage value is the hash of its slot
        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        return TriePRoofs.verify(storageProof, stateRoot, proofPath).toRLPItem().toUint();
    }

     function getHolderBalanceSlot(
        address holder,
        uint256 balanceMappingPosition
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(bytes32(holder), balanceMappingPosition)
            );
    }

    function getBalance(
        address token,
        address holder,
        uint256 blockNumber,
        bytes memory blockHeaderRLP,
        bytes memory accountStateProof,
        bytes memory storageProof,
        uint256 balanceMappingPosition
    ) public view returns (uint256) {
        uint256 holderBalanceSlot = uint256(
            getHolderBalanceSlot(holder, balanceMappingPosition)
        );
        bytes32 root = getStorageRoot(holder, blockNumber, blockHeaderRLP, accountStateProof);
        return getStorage(token, blockNumber, holderBalanceSlot, root, storageProof);
    }

    // extract state root from block header, verifying block hash
    function getBlockHeaderStateRoot(bytes memory blockHeaderRLP, bytes32 blockHash)
        public
        pure
        returns (bytes32 stateRoot)
    {
        require(blockHeaderRLP.length > 123, "invalid block header"); // prevent from reading invalid memory
        require(keccak256(blockHeaderRLP) == blockHash, "mismatch on the blockhash provided");
        // 0x7b = 0x20 (length) + 0x5b (position of state root in header, [91, 123])
        assembly {
            stateRoot := mload(add(blockHeaderRLP, 0x7b))
        }
    }
}
