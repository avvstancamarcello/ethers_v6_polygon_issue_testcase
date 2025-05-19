// testEthersDirect.js (in the project root)
const { ethers, Interface } = require("ethers");
require("dotenv").config(); // Make sure .env is in the same folder or specify the path

async function runTest() {
    const contractAddress = "0x6a6d5c29ad8f23209186775873e123b31c26e9";
    // Use the URL directly, do not get it from Hardhat config for this test
    const providerUrl = process.env.QUICKNODE_MATIC_URL;

    if (!providerUrl) {
        console.error("ERROR: QUICKNODE_MATIC_URL not defined in .env");
        return;
    }
    console.log(`Using RPC URL (direct from .env): ${providerUrl}`);

    const provider = new ethers.JsonRpcProvider(providerUrl, 137); // Specify chainId

    try {
        console.log("Attempting to call provider.getBlockNumber()...");
        const blockNumber = await provider.getBlockNumber();
        console.log(`Current block number: ${blockNumber}`);
    } catch (e) {
        console.error("--- ERROR calling provider.getBlockNumber(): ---", e.message, e.stack);
        return;
    }

    // Essential ABI for the name() function
    // Minimal ABI for the name() function
    const contractABI = [
        {
          "inputs": [],
          "name": "name",
          "outputs": [
            {
              "internalType": "string",
              "name": "",
              "type": "string"
            }
          ],
          "stateMutability": "view",
          "type": "function"
        }
    ];
    const iface = new Interface(contractABI);
    const calldata = iface.encodeFunctionData("name");

    console.log(`Attempting to read contract name with direct provider.call... Calldata: ${calldata}`);
    try {
        const result = await provider.call({
            to: contractAddress,
            data: calldata
        });
        console.log(`Raw result from provider.call: ${result}`);

        if (result === "0x" || result === null || result === undefined || result.length <= 2) {
             console.error(`Error: provider.call returned an empty or null result (${result}), cannot decode.`);
             // Add a check to see if the contract has code at that address
             const code = await provider.getCode(contractAddress);
             if (code === "0x") {
                console.error(`The address ${contractAddress} has no deployed bytecode. Verify the address and network.`);
             }
        } else {
            const decodedResult = iface.decodeFunctionResult("name", result);
            console.log(`Contract Name (from direct provider.call): ${decodedResult[0]}`);
            console.log("Test with DIRECT provider.call completed successfully.");
        }
    } catch (error) {
        console.error("--- ERROR DURING DIRECT provider.call ---");
        console.error(`Message: ${error.message}`);
        console.error("Stack:", error.stack);
    }
}

runTest();
