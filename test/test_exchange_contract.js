const Web3 = require('web3');
// const chai = require('chai');
// const BigNumber = require('bignumber.js')

const MonaContractSource = require('../build/contracts/MonaGallery.json');
const ArtistContractSource = require('../build/contracts/SimpleNFT.json');

const MonaContract = artifacts.require("MonaGallery")
const ArtistContract = artifacts.require("SimpleNFT")

const { assert, timeStamp, log, Console } = require('console');
const { equal } = require('assert');
// const { equal } = require('assert');

// const ContractSrc = artifacts.require("Contract"); 

const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));
// web3.transactionConfirmationBlocks = 1;

// contract("Test Exchange", async accounts => {
//   const 
// })

// contract("Test Exchange Functionality", accounts => {
//   it("should mint an nft to the first account", () => {
//     let _ArtistContract
//     ArtistContract.deployed()
//       .then(instance => {
//         _ArtistContract = instance
//         return 
//       })
//   })
// })

contract('test contract', async accounts => {

  let MonaContractInstance
  let ArtistContractInstance  
  // let accounts = await web3.eth.getAccounts()

  // beforeEach(async() => {
  //   MonaContractInstance = new web3.eth.Contract(MonaContractSource.abi)
  //   MonaContractInstance = await MonaContractInstance.deploy({data: MonaContractSource.bytecode}).send({ from: accounts[0], gas: 80000000 })

  //   ArtistContractInstance = new web3.eth.Contract(ArtistContractSource.abi)
  //   ArtistContractInstance = await ArtistContractInstance.deploy({data: ArtistContractSource.bytecode}).send({ from: accounts[0], gas: 80000000 })
  //   await ArtistContractInstance.methods.mint().send({from: accounts[0], gas:80000000})
  //   await ArtistContractInstance.methods.setApprovalForAll(MonaContractInstance.optionss.address, true).send({from: accounts[0], gas:80000000})
    
  // });

  it('Should buy an NFT', async () => {

      MonaContractInstance = new web3.eth.Contract(MonaContractSource.abi)
      MonaContractInstance = await MonaContractInstance.deploy({data: MonaContractSource.bytecode}).send({ from: accounts[0], gas: 10000000 })


      ArtistContractInstance = new web3.eth.Contract(ArtistContractSource.abi)
      ArtistContractInstance = await ArtistContractInstance.deploy({data: ArtistContractSource.bytecode}).send({ from: accounts[0], gas: 10000000 })

      await ArtistContractInstance.methods.mint().send({from: accounts[0], gas:1000000})
      await ArtistContractInstance.methods.setApprovalForAll(MonaContractInstance.options.address, true).send({from: accounts[0], gas:1000000})
      let ownerBalance = await ArtistContractInstance.methods.balanceOf(accounts[0]).call()      
      equal(ownerBalance, 1, "Failed to mint token")
      
      let tokenContract = ArtistContractInstance.options.address
      let artistAddr = accounts[0]
      let tokenId = 1
      let price = 10
      let percentage = 10
      let expirationTimestamp = web3.utils.toBN('2500000000000').toString()
      let nonce = 1

      let msgData = await MonaContractInstance.methods.getMsg(tokenContract, artistAddr, tokenId, price, percentage, expirationTimestamp, nonce).call()

      let sig = await web3.eth.sign(msgData, accounts[0])

      let buyerAccount = accounts[2]

      // let gasLimit = await MonaContractInstance.methods.buyNFT(tokenContract, artistAddr, tokenId, price, percentage, expirationTimestamp, nonce, sig).estimateGas({from: buyerAccount, value: price})

      await MonaContractInstance.methods.buyNFT(tokenContract, artistAddr, tokenId, price, percentage, expirationTimestamp, nonce, sig).send({from: buyerAccount, gas:1000000, value: price})

      let userTokenBalance = await ArtistContractInstance.methods.balanceOf(accounts[2]).call()
      equal(
          userTokenBalance,
          1,
          "Failed to buy token!"
      ) 
      
  })

})