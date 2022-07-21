import { ethers } from 'hardhat';

async function main() {
    const execution = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
    const voters = [
        '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
        '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    ];
    const timeout = 3600;
    const threshold = 2;

    const BallotWallet = await ethers.getContractFactory('BallotWallet');
    const ballotWallet = await BallotWallet.deploy(execution, threshold, timeout, voters);

    await ballotWallet.deployed();

    console.log(`BallotWallet deployed to address: ${ballotWallet.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
