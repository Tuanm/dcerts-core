import { ethers } from 'hardhat';

async function main() {
    const CertPoolV2 = await ethers.getContractFactory('CertPoolV2');
    const certPoolV2 = await CertPoolV2.deploy();

    await certPoolV2.deployed();

    console.log(`CertPoolV2 deployed to address: ${certPoolV2.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
