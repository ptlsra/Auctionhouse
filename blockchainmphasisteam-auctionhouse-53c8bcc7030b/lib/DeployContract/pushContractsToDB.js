const Web3 = require('web3');
const express = require('express');
var app = express();
var fs = require('fs');
var async = require('asyncawait/async');
var await = require('asyncawait/await');
var mongoUrl = "mongodb://127.0.0.1:27017/";

var solidityFileList        = ["Auction.sol"];
var solidityJsonFileList    = ["Auction.json"];
var contractNameList        = ["Auction"];
var contractAddresses=[];


let rawdata = fs.readFileSync('./AuctionContract.json');
let contractsData = JSON.parse(rawdata);
console.log(JSON.stringify(contractsData));

auctionContractAddress = contractsData.contract_address;

console.log("************* fetched contract address from config file ****************");


function pushContractToDB(solidityFileName, solidityJsonfileName, contractName, contractAddress, abi){
    var MongoClient = require('mongodb').MongoClient;
    var url = mongoUrl+"blockchaindb";
    MongoClient.connect(url, function(err, db) {
        if (err) throw err;
        console.log("************ connected to mongodb client at localhost *************");
        console.log("************ storing record **********");
        let myobj = {contractAddress:contractAddress, contractName:contractName, abi:abi};
        var collectionName = "contracts";
        db.collection(collectionName).insertOne(myobj, function(err, res) {
            if (err) throw err;
            console.log("contract abi pushed to mongodb ....");
            //console.log(res);
            db.close();
        });
    });

}





var policyContractSource = fs.readFileSync("BalanceProof.json");
var policyContract = JSON.parse(policyContractSource)["contracts"];
var policyabi = JSON.parse(policyContract["BalanceProof.sol:BalanceProof"].abi);

console.log("************** pushing Policy contract **********");
pushContractToDB(solidityFileList[0], solidityJsonFileList[0], contractNameList[0], auctionContractAddress, policyabi);