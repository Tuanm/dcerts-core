import { ethers } from 'hardhat';

async function main() {
    const ContentPool = await ethers.getContractFactory('ContentPool');
    const contentPool = await ContentPool.deploy();

    await contentPool.deployed();

    console.log(`ContentPool deployed to address: ${contentPool.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
