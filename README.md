# Ethers.js v6 - Polygon `provider.call()` Issue: "could not decode result data (value="0x", info={ "method": "resolver", ...})"

This repository provides a minimal test case to reproduce an issue encountered with `ethers.js` (v6.11.1, also observed with v6.14.1) when interacting with Polygon Mainnet. A direct `provider.call()` to a simple view function on a deployed contract, as well as contract interactions via Hardhat's ethers wrapper, unexpectedly trigger internal ENS resolver logic, which fails with a `BAD_DATA` or `UNCONFIGURED_NAME` error.

## Problem Description

We are encountering a persistent error when attempting to make simple `view` function calls (e.g., `name()`) to a deployed and verified smart contract on Polygon Mainnet (chainId 137).

1.  **When using `ethers.JsonRpcProvider.call()` directly (via a plain Node.js script):** The call fails with a `BAD_DATA` error (info: `{ "method": "resolver", "signature": "resolver(bytes32)" }`, `value="0x"`).
2.  **When using Hardhat's ethers wrapper (`hre.ethers` via `npx hardhat run scripts/...`):** The call previously failed with a `NotImplementedError: Method 'HardhatEthersProvider.resolveName' is not implemented`. After applying a workaround (overriding `provider.getResolver` to return `null`), the error changed to `UNCONFIGURED_NAME` for the contract address.

This issue has been observed with `ethers` version 6.11.1 (after downgrading from 6.14.1), across different Node.js versions (v18.20.8 LTS, and previously v22.15.1), and using different Polygon RPC providers (QuickNode, public nodes like `https://polygon-rpc.com`).

The stack traces indicate that `ethers.js` internally attempts to use `JsonRpcProvider.getResolver()` or similar ENS-related logic. This internal call to the RPC for an ENS `resolver(bytes32)` function apparently returns `0x` (no data / zero address), which `ethers.js` then fails to decode as a valid resolver address, throwing the `BAD_DATA` error. Direct provider calls like `getBlockNumber()` work correctly.

This behavior is unexpected as no ENS names are being used for the contract interaction, and the target is always a valid hexadecimal contract address.

## Environment & Versions

* **Node.js:** v18.20.8 (LTS) - *also tested with v22.15.1 with same fundamental issues*
* **npm:** v10.8.2 (with Node v18) - *also tested with v10.9.2 (with Node v22)*
* **ethers.js:** v6.11.1 - *issue also observed with v6.14.1*
* **Hardhat (for `testConnection.cjs` context):** v2.22.19
* **`@nomicfoundation/hardhat-toolbox` (for `testConnection.cjs` context):** v5.0.0
* **Network:** Polygon Mainnet (Chain ID: 137)
* **RPC Providers Tested:**
    * QuickNode (e.g., `https://proportionate-dry-brook.matic.quiknode.pro/YOUR_QUICKNODE_KEY/`)
    * Public RPC (e.g., `https://polygon-rpc.com`, `https://polygon-bor-rpc.publicnode.com`)
* **Operating System (WSL2):** Ubuntu 22.04.5 LTS
* **Host Operating System:** Windows 11 Home, Version 24H2, Build 26100.4061
* **Hardware:** PC Notebook Lenovo IdeaPad 5 14ALC05, RAM 8 Gb, AMD Ryzen 7 5700U with Radeon Graphics 1.80 GHz

## Contract Information

* **Contract Name:** LHILecceNFT
* **Deployed Address (Polygon Mainnet):** `0x6a6d5c29ad8f23209186775873e123b31c26e9`
* **PolygonScan Link:** [https://polygonscan.com/address/0x6a6d5c29ad8f23209186775873e123b31c26e9](https://polygonscan.com/address/0x6a6d5c29ad8f23209186775873e123b31c26e9)
* **Relevant Function (minimal ABI used in `testEthersDirect.js`):**
    ```json
    [
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
    ]
    ```

## Files in this Repository (Minimal Test Case)

* **`scripts/testEthersDirect.js`**: A minimal Node.js script using `ethers.js` directly (run with `node scripts/testEthersDirect.js`) to reproduce the `BAD_DATA` error. The minimal ABI for the `name()` function is embedded.
* **`scripts/testConnection.cjs`**: A Hardhat script (run with `npx hardhat run ...`) that demonstrates a similar issue (`UNCONFIGURED_NAME` after applying a `provider.getResolver` hack, or `NotImplementedError` originally) when using Hardhat's ethers wrapper. *(This script is provided for additional context on the pervasiveness of the ENS-related issues encountered).*
* **`package.json`**: Defines dependencies.
* **`.env.example`**: Example environment file.
* **`hardhat.config.cjs`**: Hardhat configuration file, relevant if running `testConnection.cjs`.
* **`contracts/LHILecceNFT.sol`**: Full source code of the smart contract.

## Steps to Reproduce

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/avvstancamarcello/ethers_v6_polygon_issue_testcase.git](https://github.com/avvstancamarcello/ethers_v6_polygon_issue_testcase.git) # Or your actual repo URL
    cd ethers_v6_polygon_issue_testcase
    ```
2.  **Install dependencies:**
    ```bash
    npm install
    ```
3.  **Set up environment variables:**
    * Create a `.env` file by copying `.env.example`.
    * Edit the `.env` file and add your Polygon Mainnet RPC URL to the `QUICKNODE_MATIC_URL` variable (e.g., your QuickNode endpoint or a public one like `https://polygon-rpc.com`). Also, add your `PRIVATE_KEY` if you intend to run scripts that require a signer (though `testEthersDirect.js` for `name()` does not strictly need it).
        ```env
        QUICKNODE_MATIC_URL="YOUR_POLYGON_MAINNET_RPC_URL_HERE"
        PRIVATE_KEY="YOUR_PRIVATE_KEY_WITHOUT_0X_PREFIX"
        ```
4.  **Run the primary test script (direct ethers.js):**
    ```bash
    node scripts/testEthersDirect.js
    ```
5.  **(Optional) Run the Hardhat context test script:**
    ```bash
    npx hardhat run scripts/testConnection.cjs --network polygon --show-stack-traces
    ```

## Expected Result

Both scripts should successfully call the `name()` view function on the contract and print the contract's name ("LHI Lecce NFT").

## Actual Result

### 1. Output from `node scripts/testEthersDirect.js` (with ethers@6.11.1):

The script successfully calls `provider.getBlockNumber()` but fails when `provider.call()` is executed for the `name()` function:

Utilizzo RPC URL (diretto da .env): https://proportionate-dry-brook.matic.quiknode.pro/752b1e43a682209ddc19a49978c10acac9458739
Tentativo di chiamare provider.getBlockNumber()...
Numero blocco attuale: 71674569
Tentativo di leggere il nome del contratto con provider.call... Calldata: 0x06fdde03
--- ERRORE DURANTE provider.call DIRETTO ---
Messaggio: could not decode result data (value="0x", info={ "method": "resolver", "signature": "resolver(bytes32)" }, code=BAD_DATA, version=6.11.1)
Stack: Error: could not decode result data (value="0x", info={ "method": "resolver", "signature": "resolver(bytes32)" }, code=BAD_DATA, version=6.11.1)
at makeError (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/utils/errors.js:129:21)
at assert (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/utils/errors.js:149:15)
at Interface.decodeFunctionResult (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/abi/interface.js:780:31)
at staticCallResult (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/contract/contract.js:254:35)
at process.processTicksAndRejections (node:internal/process/task_queues:95:5)
at async staticCall (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/contract/contract.js:219:24)
at async Proxy.resolver (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/contract/contract.js:259:20)
at async #getResolver (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/providers/ens-resolver.js:455:26)
at async EnsResolver.fromName (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/providers/ens-resolver.js:486:26)
at async JsonRpcProvider.getResolver (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/lib.commonjs/providers/abstract-provider.js:832:16)

### 2. Output from `npx hardhat run scripts/testConnection.cjs --network polygon` 
(with ethers@6.11.1 and `provider.getResolver` hack applied in script):

This script, when using Hardhat's ethers provider and applying a hack to make `provider.getResolver` return `null`, 
still fails, but with a different error, further indicating ENS involvement:
Target network specified: polygon
Using RPC URL: https://proportionate-dry-brook.matic.quiknode.pro/MY_QUICKNODE_RPC_ENDPOINT
Attempting to call provider.getBlockNumber()...
Current block number: 71640171
Attempting to get ENS resolver for 'unlikelyname.eth'...
[HACK] provider.getResolver called for: unlikelyname.eth, returning null.
ENS Resolver for 'unlikelyname.eth': null
Attempting to connect with account: 0xf9909c6CD90566BD56621EE0cAc42986ae334Ea3
*(Please ensure to replace `YOUR_RPC_URL_PART`, `... (other logs) ...`, and the specific function call in the stack 
trace (`Proxy.pricesInWei` or `Proxy.name`) and `LINE_NUMBER:COLUMN_NUMBER` with the actual details from your original error log for this specific test.)*

This demonstrates that the ENS-related issues or provider interaction problems were present even 
when using the standard Hardhat ethers integration, manifesting as a `NotImplementedError` within the `HardhatEthersProvider`.

Important Notes:
Original Error Context: I recall that the `NotImplementedError: Method 'HardhatEthersProvider.resolveName'` 
error occurred when using `hre.ethers` (i.e., the provider and signer managed by Hardhat). The `testConnection.cjs` 
script that I used to produce the `UNCONFIGURED_NAME` or `BAD_DATA` error was a modified version that directly used
`new ethers.JsonRpcProvider()` and `new ethers.Wallet()`. It's important to provide the correct stack trace for each error scenario.

Placeholder in Stack Trace: In the stack trace I provided [referring to a previous draft of the README or issue], there is `// ... (rest of stack trace for this specific error) ...`. Please replace this line with the complete and relevant stack trace for the `NotImplementedError`.

Account balance: 365.977862946638599478 MATIC
Loading contract ABI from artifacts...
Contract ABI loaded successfully.
Connected to contract instance at address: 0x6a6d5c29ad8f23209186775873e123b31c26e9
Attempting to read contract name (view function)...
[HACK] provider.getResolver called for: 0x6a6d5c29ad8f23209186775873e123b31c26e9, returning null.
--- ERROR DURING CONNECTION OR READ TEST (WITH DIRECT ethers.js PROVIDER AND SIGNER) ---
Message: unconfigured name (value="0x6a6d5c29ad8f23209186775873e123b31c26e9", code=UNCONFIGURED_NAME, version=6.11.1)
Stack trace: Error: unconfigured name (value="0x6a6d5c29ad8f23209186775873e123b31c26e9", code=UNCONFIGURED_NAME, version=6.11.1)
    at makeError (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/utils/errors.ts:694:21)
    at assert (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/utils/errors.ts:715:25)
    at checkAddress (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/address/checks.ts:62:15)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at async Promise.all (index 0)
    at resolveProperties (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/utils/properties.ts:35:21)
    at populate (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/providers/abstract-signer.ts:50:12)
    at Wallet.populateCall (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/providers/abstract-signer.ts:91:21)
    at Wallet.call (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/providers/abstract-signer.ts:221:49)
    at staticCallResult (/home/avvocato/LHI-NFT-CORRETTO/node_modules/ethers/src.ts/contract/contract.ts:337:22)
---------------------------------------------------------------------------------------------

The script Hardhat `testConnection.cjs` original (whitouthack) produceva l'errore `NotImplementedError: Method 'HardhatEthersProvider.resolveName'`
## Additional Context
### 2. Initial Output from `npx hardhat run scripts/testConnection.cjs --network polygon` (using `hre.ethers` wrapper, before direct provider tests and without hacks):

The original Hardhat script `testConnection.cjs` (without any hacks, using `hre.ethers`) produced the `NotImplementedError: Method 'HardhatEthersProvider.resolveName'` error.

When initially attempting to read contract data (e.g., `pricesInWei` or `name()`) using Hardhat's ethers wrapper 
(`hre.ethers.getContractFactory` and contract instance methods via `hre.ethers`), the following error was observed:

The core issue appears to be that `ethers.js` v6 (tested with v6.11.1 and v6.14.1) incorrectly triggers ENS resolution logic 
(specifically involving a call to a method like `resolver(bytes32)` internally via `JsonRpcProvider.getResolver`) 
even when a direct hexadecimal address is provided for a contract call on Polygon Mainnet (chainId 137). 
The RPC provider's response of `0x` to this internal ENS-related query is then not handled gracefully, 
leading to a `BAD_DATA` error when `ethers.js` attempts to decode `0x` as a valid resolver address. 
This makes basic view function calls using `provider.call()` (and by extension, `Contract` object interactions) unreliable under these conditions.

Any insights or guidance on how to correctly perform `provider.call()` or contract view function calls on Polygon
with `ethers.js` v6 without triggering this ENS-related error pathway would be greatly appreciated.
