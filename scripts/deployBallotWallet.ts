import { ethers } from 'hardhat';

async function main() {
    const voters = [
        '0x000',
        '0x001',
    ];
    const timeout = 600;
    const threshold = 2;

    const BallotWallet = await ethers.getContractFactory('BallotWallet');
    const ballotWallet = await BallotWallet.deploy(threshold, timeout, voters);

    await ballotWallet.deployed();

    console.log(`BallotWallet deployed to address: ${ballotWallet.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
