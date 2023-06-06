import { ethers } from 'hardhat';

async function main() {
    const [deployer] = await ethers.getSigners();
    const balance = await deployer.getBalance();
    console.log(`Deployer: ${deployer.address}, Balance: ${balance.toString()}`);

    const ContentPool = await ethers.getContractFactory('ContentPoolV2');
    const contentPool = await ContentPool.deploy();
    await contentPool.deployed();
    console.log(`ContentPool deployed to address: ${contentPool.address}`);

    const BallotWallet = await ethers.getContractFactory('BallotWallet');
    const ballotWallet = await BallotWallet.deploy(
        contentPool.address,
        2,
        3600,
        [
            '0xE52E8dE016591302d9Be0fbD93EA7e4b21a910b8',
            '0xBad35b0833094dd410781585A7F5321654816ab9',
            '0x5248f7Fe2254a2dD6AEbaD5D11b4860e06C2aeAf',
        ],
    );
    await ballotWallet.deployed();
    console.log(`BallotWallet deployed to address: ${ballotWallet.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
