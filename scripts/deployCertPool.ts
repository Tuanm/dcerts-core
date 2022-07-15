import { ethers } from 'hardhat';

async function main() {
    const CertPool = await ethers.getContractFactory('CertPool');
    const certPool = await CertPool.deploy();

    await certPool.deployed();

    console.log(`CertPool deployed to address: ${certPool.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
