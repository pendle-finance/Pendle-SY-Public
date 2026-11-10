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
            'contracts/core/StandardizedYield/implementations/Ethena/PendleEthenaCreditSY.sol': {
                version: '0.8.34',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 0,
                    },
                    evmVersion: 'cancun',
                },
            },
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
