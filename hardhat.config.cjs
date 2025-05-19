// hardhat.config.cjs
require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

// Load necessary environment variables
const PRIVATE_KEY_FROM_ENV = process.env.PRIVATE_KEY;
const QUICKNODE_MATIC_URL_FROM_ENV = process.env.QUICKNODE_MATIC_URL;
const POLYGON_RPC_URL_FROM_ENV = process.env.POLYGON_RPC_URL; // Will be undefined if commented out in .env
const AMOY_RPC_URL_FROM_ENV = process.env.AMOY_RPC_URL;
// ... load other RPC URLs and API keys you use ...
const POLYGONSCAN_API_KEY_FROM_ENV = process.env.POLYGONSCAN_API_KEY;


if (!PRIVATE_KEY_FROM_ENV) {
  // Don't throw an error here, but log a warning.
  // Hardhat will still fail if a selected network requires an undefined key.
  console.warn("WARNING: The PRIVATE_KEY environment variable is not defined in the .env file. Operations requiring a signer will fail.");
}

// Prepare accounts configuration, handling the '0x' prefix
// This will be used for all networks requiring this key.
const accountsConfig = PRIVATE_KEY_FROM_ENV
  ? PRIVATE_KEY_FROM_ENV.startsWith("0x")
    ? [PRIVATE_KEY_FROM_ENV]
    : [`0x${PRIVATE_KEY_FROM_ENV}`]
  : [];

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: { // Good practice to add the optimizer
        enabled: true,
        runs: 200,
      },
    }
  },
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545",
      // accounts: accountsConfig, // Optional
    },
    myQuickNode: { // If you still want a separate network to test a QuickNode URL directly
      url: "https://aged-tiniest-frost.matic.quiknode.pro/b50bb4625032afb94b57bf5efd6082700059e0da8/", // You can also use QUICKNODE_MATIC_URL_FROM_ENV here
      accounts: accountsConfig,
      chainId: 137, // Make sure the chainId is correct if this URL is not for Polygon Mainnet
    },
    polygon: {
      // Fallback logic: use POLYGON_RPC_URL_FROM_ENV if defined, otherwise QUICKNODE_MATIC_URL_FROM_ENV,
      // otherwise a public RPC as a last resort (or fails if none are valid)
      url: POLYGON_RPC_URL_FROM_ENV || QUICKNODE_MATIC_URL_FROM_ENV || "https://polygon-rpc.com",
      accounts: accountsConfig,
      chainId: 137,
    },
    amoy: {
      url: AMOY_RPC_URL_FROM_ENV || "https://rpc-amoy.polygon.technology/", // Fallback to public Amoy RPC
      accounts: accountsConfig,
      chainId: 80002,
    },
    // ... (define base, baseSepolia, sepolia, ethereum similarly, using their respective _FROM_ENV variables
    //      and adding public RPC fallbacks if desired)
    base: {
      url: process.env.BASE_RPC_URL || "", // Add fallback if necessary
      accounts: accountsConfig,
      chainId: 8453,
    },
    baseSepolia: {
      url: process.env.BASE_SEPOLIA_RPC_URL || "", // Add fallback if necessary
      accounts: accountsConfig,
      chainId: 84532,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "", // Add fallback if necessary
      accounts: accountsConfig,
      chainId: 11155111,
    },
    ethereum: {
      url: process.env.ETHEREUM_RPC_URL || "", // Add fallback if necessary
      accounts: accountsConfig,
      chainId: 1,
    },
  },
  etherscan: {
    apiKey: {
      polygon: POLYGONSCAN_API_KEY_FROM_ENV,
      polygonAmoy: POLYGONSCAN_API_KEY_FROM_ENV, // Amoy uses the same Polygonscan key
      // ... (other API keys for base, sepolia, etc.)
      base: process.env.BASESCAN_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
    },
    customChains: [
      // ... (your customChains definitions are generally correct) ...
      { network: "base", chainId: 8453, urls: { apiURL: "https://api.basescan.org/api", browserURL: "https://basescan.org" }},
      { network: "baseSepolia", chainId: 84532, urls: { apiURL: "https://api-sepolia.basescan.org/api", browserURL: "https://sepolia.basescan.org" }},
      { network: "sepolia", chainId: 11155111, urls: { apiURL: "https://api-sepolia.etherscan.io/api", browserURL: "https://sepolia.etherscan.io" }},
      { network: "amoy", chainId: 80002, urls: { apiURL: "https://api-amoy.polygonscan.com/api", browserURL: "https://amoy.polygonscan.com/" }},
    ],
  },
  sourcify: {
    enabled: false,
  },
};
