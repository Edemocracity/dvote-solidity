var VotingProcess = artifacts.require("VotingProcess")

contract('VotingProcess', function (accounts) {

    let organizerAddress = accounts[0]

    it("Checks no process exists", async () => {
        let instance = await VotingProcess.deployed()
        let processesLength = await instance.getProcessesLength({ from: accounts[0] })
        assert.equal(processesLength.valueOf(), 0, "processess index should be empty")
    });

    input = {
        name: "This is a process name",
        startBlock: 0,
        endBlock: 0,
        censusMerkleRoot: "0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        voteEncryptionPublicKey: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        voteEncryptionPrivateKey: "0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
    }

    it("Creates a new process", async () => {
        let instance = await VotingProcess.deployed()
        await instance.createProcess(
            input.name,
            input.startBlock,
            input.endBlock,
            input.censusMerkleRoot,
            input.voteEncryptionPublicKey,
            { from: organizerAddress })

        let processesLength = await instance.getProcessesLength({ from: organizerAddress })
        assert.equal(processesLength.valueOf(), 1, "Only one process exists")

        let processIdByIndex = await instance.getProcessIdByIndex(0, { from: organizerAddress })

        let processId = await instance.getProcessId(organizerAddress, input.name, { from: organizerAddress })
        assert.equal(processIdByIndex, processId, "The processId should be the same")
    })

    it("Metadata is stored correctly", async () => {
        let instance = await VotingProcess.deployed()
        let processId = await instance.getProcessId(organizerAddress, input.name, { from: organizerAddress })
        let processMetadata = await instance.getProcessMetadata(processId, { from: organizerAddress })

        assert.equal(processMetadata.name, input.name, "The name should match the input")
        assert.equal(processMetadata.startBlock, input.startBlock.valueOf(), "The startBlock should match the input")
        assert.equal(processMetadata.endBlock, input.endBlock.valueOf(), "The endBlock should match the input")
        assert.equal(processMetadata.censusMerkleRoot, input.censusMerkleRoot, "The censusMerkleRoot should match the input")
        assert.equal(processMetadata.voteEncryptionPublicKey, input.voteEncryptionPublicKey, "The voteEncryptionPublicKey should match the input")
        
        assert.equal(processMetadata.voteEncryptionPrivateKey, "", "The voteEncryptionPrivateKey should empty until the process is finished")
    })

    it("Finishes the process", async () => {
        let instance = await VotingProcess.deployed()
        let processId = await instance.getProcessId(organizerAddress, input.name, { from: organizerAddress })
        await instance.finishProcess(
            processId,
            input.voteEncryptionPrivateKey,
            { from: organizerAddress })

        let processMetadata = await instance.getProcessMetadata(processId, { from: organizerAddress })

        assert.equal(processMetadata.voteEncryptionPrivateKey, input.voteEncryptionPrivateKey, "The voteEncryptionPrivateKey should match the input")
       
    })
})