import '@typechain/hardhat';
import "hardhat-contract-sizer";
import { HardhatUserConfig } from "hardhat/types";

function viaIR(version: string, runs: number) {
    return {
        version,
        settings: {
            optimizer: {
                enabled: true,
                runs: runs,
            },
            evmVersion: 'cancun',
            viaIR: true,
        },
    };
}

const config: HardhatUserConfig = {
    paths: {
        sources: './contracts',
        tests: './test',
        artifacts: "./build/artifacts",
        cache: "./build/cache"
    },
    solidity: {
        compilers: [
            viaIR('0.8.30', 0)
        ],
        overrides: {
        },
    },
    contractSizer: {
        disambiguatePaths: false,
        runOnCompile: false,
        strict: true,
        only: [],
    }
};

export default config;
