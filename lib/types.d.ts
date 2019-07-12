import { ContractTransaction } from "ethers"
import { BigNumber } from "ethers/utils"

///////////////////////////////////////////////////////////////////////////////
// ENTITY RESOLVER
///////////////////////////////////////////////////////////////////////////////

/** Custom Smart Contract operations for an Entity Resolver contract */
export type EntityResolverContractMethods = {
    /** Whether the resolver supports an interface */
    supportsInterface(interfaceID: string): Promise<boolean>

    /** Get the entity ID for a given Ethereum address */
    getEntityId(entityAddress: string): Promise<string>

    /** Get the address associated with the given node */
    addr(node: string): Promise<string>
    /** Sets the address for the given node */
    setAddr(node: string, address: string): Promise<ContractTransaction>

    /**
     * Returns the text associated with an ENS node and key.
     * @param entityId The ENS node to query.
     * @param key The key to retrieve.
     * @return The record's text.
     */
    text(entityId: string, key: string): Promise<string>
    /**
     * Sets the text of the ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param entityId The ENS node to modify.
     * @param key The key to modify.
     * @param value The text to store.
     */
    setText(entityId: string, key: string, value: string): Promise<ContractTransaction>

    /**
     * Returns the list associated with an ENS node and key.
     * @param entityId The ENS node to query.
     * @param key The key of the list.
     * @return The list array of values.
     */
    list(entityId: string, key: string): Promise<string[]>
    /**
     * Returns the text associated with an ENS node, key and index.
     * @param entityId The ENS node to query.
     * @param key The key of the list.
     * @param index The index within the list to retrieve.
     * @return The list entry's text value.
     */
    listText(entityId: string, key: string, index: number): Promise<string>
    /**
     * Sets the text of the ENS node, key and index.
     * May only be called by the owner of that node in the ENS registry.
     * @param entityId The ENS node to modify.
     * @param key The key of the list to modify.
     * @param index The index of the list to set.
     * @param value The text to store.
     */
    setListText(entityId: string, key: string, index: number, value: string): Promise<ContractTransaction>
    /**
     * Appends a new value on the given ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param entityId The ENS node to modify.
     * @param key The key of the list to modify.
     * @param value The text to store.
     */
    pushListText(entityId: string, key: string, value: string): Promise<ContractTransaction>
    /**
     * Removes the value on the ENS node, key and index.
     * May only be called by the owner of that node in the ENS registry.
     * Note: This may cause items to be arranged in a different order.
     * @param entityId The ENS node to modify.
     * @param key The key of the list to modify.
     * @param index The index to remove.
     */
    removeListIndex(entityId: string, key: string, index: number): Promise<ContractTransaction>
}

///////////////////////////////////////////////////////////////////////////////
// VOTING PROCESS
///////////////////////////////////////////////////////////////////////////////

/** Smart Contract operations for a Voting Process contract */
export interface VotingProcessContractMethods {
    getNextProcessId(entityAddress: string): Promise<string>
    getProcessId(entityAddress: string, processIndex: number): Promise<string>

    create(entityResolver: string, processName: string, metadataContentUri: string, startTime: BigNumber, endTime: BigNumber, voteEncryptionPublicKey: string): Promise<ContractTransaction>
    get(processId: string): Promise<VotingProcessData>
    cancel(processId: string): Promise<ContractTransaction>

    addRelay(processId: string, relayAddress: string, publicKey: string, messagingUri: string): Promise<ContractTransaction>
    disableRelay(processId: string, relayAddress: string): Promise<ContractTransaction>
    getRelayIndex(processId: string): Promise<string[]>
    isActiveRelay(processId: string, relayAddress: string): Promise<boolean>
    getRelay(processId: string, relayAddress: string): Promise<RelayData>

    registerVoteBatch(processId: string, dataContentUri: string): Promise<ContractTransaction>
    getVoteBatchCount(processId: string): Promise<number>
    getBatch(processId: string, batchNumber: number): Promise<string>

    revealPrivateKey(processId: string, privateKey: string): Promise<ContractTransaction>
    getPrivateKey(processId: string): Promise<string>
}

type VotingProcessData = {
    entityResolver: string,
    entityAddress: string,
    processName: string,
    metadataContentUri: string,
    startTime: BigNumber,
    endTime: BigNumber,
    voteEncryptionPublicKey: string,
    canceled: boolean
}
type RelayData = {
    publicKey: string,
    messagingUri: string
}
