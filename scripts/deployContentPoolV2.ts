import { ethers } from 'hardhat';

async function main() {
    const ContentPoolV2 = await ethers.getContractFactory('ContentPoolV2');
    const contentPoolV2 = await ContentPoolV2.deploy();

    await contentPoolV2.deployed();

    console.log(`ContentPoolV2 deployed to address: ${contentPoolV2.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
