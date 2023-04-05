const {expect} = require('chai');
const {ethers} = require('hardhat');
const IERC20 = require("../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json")

describe('BetContract', () => {
    let deployer, balaji, anon, betContract, wbtcAddress, usdcAddress, btcPriceFeed, usdcPriceFeed
    let wbtcContract, usdcContract
    // WBTC & USDC addresses on Polygon
    wbtcAddress = '0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6' //'0x260eDFFa7648ddC398b91884D78485612fC6d246'
    usdcAddress = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174' //'0xd787Ec2b6C962f611300175603741Db8438674a0'
    // ChainLink price feeds for the prices of BTC & USDC against the real-world fiat dollar
    btcPriceFeed = '0xc907E116054Ad103354f2D350FD2514433D57F6f' //'0xA39434A63A52E749F02807ae27335515BA4b07F7'
    usdcPriceFeed = '0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7' //'0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7'
    
    beforeEach(async() => {
        [deployer, balaji, anon] = await ethers.getSigners()
        const BetContract = await ethers.getContractFactory('BetContract', deployer)
        // Deploy the betContract with arguments (Balaji's address, Anon's address, token addresses and pricefeed addresses).
        betContract = await BetContract.deploy(
            balaji.address, anon.address, wbtcAddress, usdcAddress, btcPriceFeed, usdcPriceFeed
        )
        await betContract.deployed()
        console.log(betContract.address)
        // After contract has beeen deployed, attach the contract address and interact
        //betContract = BetContract.attach('0xE1F097b3c089F8F5cd6f2eAD6261912404570341')

        provider = ethers.provider
        wbtcContract = new ethers.Contract(wbtcAddress, IERC20.abi, provider)
        usdcContract = new ethers.Contract(usdcAddress, IERC20.abi, provider)
    })

    describe('Enables both parties to place their bets', () => {
        it('permits deposits of WBTC and USDC', async() => {
            //console.log(betContract.address)
            //console.log(wbtcContract.address)
            //console.log(usdcContract.address)

            // Approve the spending of USDC and WBTC tokens by Balaji and Anon respectively.
            /*await wbtcContract.connect(anon).functions.approve(betContract.address, ethers.utils.parseEther('0.1'))
            expect(Number(
                await wbtcContract.connect(anon).functions.allowance(anon.address, betContract.address)
            )).to.equal(Number(ethers.utils.parseEther('0.1')))

            await usdcContract.connect(balaji).functions.approve(betContract.address, ethers.utils.parseEther('1'))
            expect(Number(
                await usdcContract.connect(balaji).functions.allowance(balaji.address, betContract.address)
            )).to.equal(Number(ethers.utils.parseEther('1')))*/

            // Deposit funds into the smart contract
            /*await betContract.connect(balaji).functions.depositUSDC(
                {gasLimit: 300000, gasPrice: Number(ethers.utils.parseUnits('200', 'gwei'))}
            )
            await betContract.connect(anon).functions.depositWBTC(
                {gasLimit: 300000, gasPrice: Number(ethers.utils.parseUnits('200', 'gwei'))}
            )*/
            console.log(await betContract.getBTCPriceFeed())
            console.log(Number(await betContract.getUSDCPriceFeed()))
            console.log(Number(await betContract.btcPriceInUSDC()))
            // Cancel the bet if one party has not committed funds yet
            /*await betContract.connect(anon).functions.cancelBeforeInitiation({
                gasLimit: 300000, gasPrice: Number(ethers.utils.parseUnits('200', 'gwei'))
            })*/

            // Settle the debt after the time has elapsed.
            await betContract.functions.settleBet(
                {gasLimit: 300000, gasPrice: Number(ethers.utils.parseUnits('200', 'gwei'))}
            )
            console.log(await usdcContract.functions.balanceOf(balaji.address))
            console.log(await wbtcContract.functions.balanceOf(anon.address))
            console.log(await usdcContract.functions.balanceOf(anon.address))
            
            //console.log(await usdcContract.functions.balanceOf(betContract.address))
            //console.log(await wbtcContract.functions.balanceOf(betContract.address))
        })
    })
})