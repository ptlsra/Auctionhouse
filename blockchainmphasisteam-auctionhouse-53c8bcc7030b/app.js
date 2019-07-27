//Auction house API
var log4js = require('log4js');
var fs = require("fs");
var Web3 = require('web3');
var logger = log4js.getLogger('app.js');
var express = require('express');
const path = require('path');

//var MongoClient = require('mongodb').MongoClient;
const app = express();
var MongoClient = require('mongodb').MongoClient;
const fileUpload = require('express-fileupload');
var cors = require('cors');

var pathval=__dirname + "";  // or directory name of ui folder
app.use(express.static(__dirname+"/UI/"));
app.set('views',pathval);

let configRawData = fs.readFileSync('config.json');
let configData = JSON.parse(configRawData);
logger.level = configData.logLevel;
var appIp = configData.appIp;
var appPort = configData.appPort;
var web3Url = configData.web3Url;
var mongodb_ip = configData.mongodb_ip;
var mongodb_port = configData.mongodb_port;
var deployContract = require('./lib/DeployContract/deployContract');
var web3 = new Web3(new Web3.providers.HttpProvider(web3Url));
var BigNumber = require('bignumber.js');
app.use(cors());
app.options("*",cors());

var pathval=__dirname + "";  // or directory name of ui folder
app.use(express.static(__dirname));
app.set('views',pathval);


var SolidityCoder = require("web3/lib/solidity/coder.js");

/**
 * BalanceProof.sol
 */
let rawdata = fs.readFileSync('./lib/DeployContract/BalanceProofContract.json');
let contractsData = JSON.parse(rawdata);
var balanceProofAddress = contractsData.contract_address;
var balanceProofSource = fs.readFileSync("./lib/DeployContract/BalanceProof.json");
var balanceContract = JSON.parse(balanceProofSource)["contracts"];
var balanceProofABI = JSON.parse(balanceContract["BalanceProof.sol:BalanceProof"].abi);
const deployedBalancedProofContract = web3.eth.contract(balanceProofABI).at(String(balanceProofAddress));


/**
 * Verifier.sol
 */
var verifierRawdata = fs.readFileSync('VerifierContractAddress.json');
var verifierContractData = JSON.parse(verifierRawdata);
var verifierContractAddress = verifierContractData.contract_address;
var verifierSource = fs.readFileSync("Verifier.json");
var verifierContract = JSON.parse(verifierSource)["contracts"];
var verifierABI = JSON.parse(verifierContract["AuctionhouseVerifier.sol:Verifier"].abi);
var deployedVerifierContract = web3.eth.contract(verifierABI).at(String(verifierContractAddress));


let auctionRawData = fs.readFileSync('./lib/DeployContract/AuctionContract.json');
let auctionContractData = JSON.parse(auctionRawData);
var auctionContractAddress = auctionContractData.contract_address;
var auctionSource = fs.readFileSync("./lib/DeployContract/Auction.json");
var auctionContract = JSON.parse(auctionSource)["contracts"];
var auctionABI = JSON.parse(auctionContract["Auction.sol:Auction"].abi);
const deployedAuctionContract = web3.eth.contract(auctionABI).at(String(auctionContractAddress));

app.use(fileUpload());




var auctiondb;
var auctiondbUrl = "mongodb://"+mongodb_ip+":"+mongodb_port+"/auctiondb";
console.log(auctiondbUrl);
MongoClient.connect(auctiondbUrl, function(err, auctiondbTemp) {
    auctiondb = auctiondbTemp;
});



/**
 * 
 * verifyTx Event.
 */
var verifiedEvent;

/**
 * 
 * unverifier Event
 */
var unverifiedEvent;

startVerifierEvents();

/**
 * 
 * registerAuctonItemEvent Event
 */
var registerAuctionItemEvent;
registerAuctionItemEvent = deployedAuctionContract.RegisterAuctionItem({}, {fromBlock: 'latest',toBlock:'latest'});
registerAuctionItemEvent.watch(function(error, result){
    logger.info("registerAuctionItem event");
    logger.debug("result : "+JSON.stringify(result));

    //create collection by name {auctionItem}
    let collectionName = (result.args.auctionItemName).toLowerCase();
    let txLogRaw = result.args;
    storeAuctionItemTx(collectionName, result, txLogRaw);
});


/**
 * 
 * bidForItemEvent Event
 */
var bidForItemEvent;
bidForItemEvent = deployedAuctionContract.BidForItem({}, {fromBlock: 'latest', toBlock:'latest'});
bidForItemEvent.watch(function(error, result){
    logger.info("bidForItemEvent");
    logger.debug("result : "+JSON.stringify(result));

    //create a record in the collection {auctionItem}
    let collectionName = (result.args.auctionItemName).toLowerCase();

    let txLogRaw = {
        auctionItemName:result.args.auctionItemName,
        bidderName:web3.toUtf8(result.args.bidderName),
        bidderAddress:result.args.bidderAddress,
        value:parseInt(result.args.value)
    }

    storeAuctionItemTx(collectionName, result,txLogRaw);
});

/**
 * @function getUserInfo
 * 
 */
app.get('/getUserInfo',function(request, response){
    var emailAddress = request.query.emailAddress;
    logger.debug("emailAddress : "+emailAddress);

    var userDetailsArray = deployedBalancedProofContract['getUserDetails'](emailAddress);
    
        let customerWalletAddress = userDetailsArray[0];
        let isRegistered =  userDetailsArray[1];
        var responseMessage = {
            customerAddress:customerWalletAddress,
            isRegistered:isRegistered
        }
        response.send(responseMessage);
});


/**
 * 
 * API to verify proof.
 * 
 */
app.post('/submitForVerifyTx', function(request, response){
    logger.info("submitForVerifyTx");
    logger.debug("printing contract address : "+verifierContractAddress);
    //var customerAddress = request.query.customerAddress;
    var emailAddress = request.query.emailAddress;
    var userDetailsArray = deployedBalancedProofContract['getUserDetails'](emailAddress);
    
    let customerAddress = userDetailsArray[0];

    //getProofData from balance proof contract
    var A = deployedBalancedProofContract["getA"](customerAddress);
    var A_p = deployedBalancedProofContract["getA_p"](customerAddress);
    var B = deployedBalancedProofContract["getB"](customerAddress);
    var B_p = deployedBalancedProofContract["getB_p"](customerAddress);
    var C = deployedBalancedProofContract["getC"](customerAddress);
    var C_p = deployedBalancedProofContract["getC_p"](customerAddress);
    var H = deployedBalancedProofContract["getH"](customerAddress);
    var K = deployedBalancedProofContract["getK"](customerAddress);
    var I = deployedBalancedProofContract["getInput"](customerAddress);

    var a = [];
    var a_p = [];
    var b = [];
    var bFirst = [];
    var bSecond = [];

    var b_p = [];
    var c = [];
    var c_p = [];
    var h = [];
    var k = [];
    var i = [];

    a.push(web3.toHex(A[0]));
    a.push(web3.toHex(A[1]));

    a_p.push(web3.toHex(A_p[0]));
    a_p.push(web3.toHex(A_p[1]));

    bFirst.push(web3.toHex(B[0][0]));
    bFirst.push(web3.toHex(B[0][1]));

    bSecond.push(web3.toHex(B[1][0]));
    bSecond.push(web3.toHex(B[1][1]));

    b.push(bFirst);
    b.push(bSecond);

    b_p.push(web3.toHex(B_p[0]));
    b_p.push(web3.toHex(B_p[1]));

    c.push(web3.toHex(C[0]));
    c.push(web3.toHex(C[1]));

    c_p.push(web3.toHex(C_p[0]));
    c_p.push(web3.toHex(C_p[1]));

    h.push(web3.toHex(H[0]));
    h.push(web3.toHex(H[1]));

    k.push(web3.toHex(K[0]));
    k.push(web3.toHex(K[1]));


    logger.debug("Printing value of I : "+I);


    i.push((I[0]));
    i.push((I[1]));
    i.push((I[2]));
    i.push((I[3]));
    logger.debug("printing i "+i);
    logger.info("Printing proof data : ");
    logger.debug(a);
    logger.debug(a_p);

    logger.debug(b);
    logger.debug(b_p);
    logger.debug(c);
    logger.debug(c_p);
    logger.debug(h);
    logger.debug(k);
    logger.debug(i);

    web3.personal.unlockAccount(web3.eth.accounts[0], "");

    var txId = deployedVerifierContract["verifyTx"](
        a,
        a_p,
        b,
        b_p,
        c,
        c_p,
        h,
        k,
        i,
        {
        from:String(web3.eth.accounts[0]), 
        gas: 4000000
    });

    logger.debug("transactionId for verifyTx = "+txId);

    logger.info("pushing txId to Auction contract ");

    var unixTimestamp = Math.round((new Date()).getTime() / 1000);
    logger.debug("current unix timestamp : "+unixTimestamp);
    unixTimestamp = unixTimestamp + 86400;
    var auctionTxId = deployedAuctionContract["setAuctionAuth"](customerAddress, txId, unixTimestamp,{
        from:String(web3.eth.accounts[0]),
        gas: 4000000
    });
    logger.debug("txId for auction : "+auctionTxId);
    
    //store proof status in mongo
    storeProofStatus(emailAddress, "submitted");

    response.send({
        transactionId : txId
    });
});


/**
 * API to verify tx status
 * 
 */
app.get('/verifyTxStatus', function (request, response) {
    logger.info("verifyTxStatus");
    //var customerAddress = request.query.customerAddress;
    var emailAddress = request.query.emailAddress;
    logger.debug("emailAddress : " + emailAddress);
    var userDetailsArray = deployedBalancedProofContract['getUserDetails'](emailAddress);
    let customerAddress = userDetailsArray[0];


    logger.debug("customerAddress : " + customerAddress);

    try {
        var auctionArray = deployedAuctionContract["getAuctionAuthData"](customerAddress);
        logger.debug("auctionArray : " + auctionArray);

        var transactionReceipt = web3.eth.getTransactionReceipt(auctionArray[1]);

        var logs = transactionReceipt.logs;
        logger.debug("transactionLog : " + JSON.stringify(logs));
        var logData = logs[0];
        let transactionData = SolidityCoder.decodeParams(["string"], logData.data.replace("0x", ""));
        logger.debug("transactionData : " + transactionData);
        var responseData = "Verification pending";
        var unixTimestamp = Math.round((new Date()).getTime() / 1000);

        if (transactionData == "Transaction successfully verified.") {
            responseData = "Verification successfull"
        } else {
            if (transactionData == "Transaction verification failed") {
                responseData = "Verification failed"
            }
        }
        response.send({
            transactionStatus: responseData,
            customerAddress: customerAddress
        });
    } catch (e) {
        logger.error("Error in verifyTxStatus : " + e);
        var responseData = "Verification pending";

        response.send({
            transactionStatus: responseData,
            customerAddress: customerAddress
        })
    }
});


app.get('/getProofStatus', function (request, response) {
    logger.info("getProofStatus");
    var emailAddress = request.query.emailAddress;

    logger.debug("emailAddress : " + emailAddress);

    try {

        //get customer wallet address
        var userDetailsArray = deployedBalancedProofContract['getUserDetails'](emailAddress);
        let customerAddress = userDetailsArray[0];

        // get auctionAuthData
        var auctionArray = deployedAuctionContract["getAuctionAuthData"](customerAddress);
        logger.debug("auctionArray : " + auctionArray);


        //get proof status from the database
        var query = {
            emailAddress: emailAddress
        };

        auctiondb.collection("proofstatus").find(query).toArray(function (err, result) {
            logger.debug("result : " + result);
            var customerRecord = result[0];
            logger.debug("customerRecord : " + customerRecord);
            //let proofStatus = customerRecord.proofStatus;
            //logger.debug("proofStatus : "+proofStatus);

            if (customerRecord == null) {
                logger.warn("Proof not submitted yet");
                response.send({
                    message: "proof not submitted"
                });

            } else {

                //check transactionReciept

                try {
                    var transactionReceipt = web3.eth.getTransactionReceipt(auctionArray[1]);

                    var logs = transactionReceipt.logs;
                    logger.debug("transactionLog : " + JSON.stringify(logs));
                    var logData = logs[0];

                    //decode log data
                    let transactionData = SolidityCoder.decodeParams(["string"], logData.data.replace("0x", ""));
                    logger.debug("transactionData : " + transactionData);
                    var responseData = "Verification pending";

                    if (transactionData == "Transaction successfully verified.") {
                        responseData = "verification successful"
                    } else {
                        if (transactionData == "Transaction verification failed") {
                            responseData = "verification failed"
                        }
                    }
                    response.send({
                        status: responseData,
                        message: "proof submitted"
                    });
                } catch (e) {
                    logger.error("Error in getProofStatus : " + e);
                    response.send({
                        message: "proof submitted",
                        status: "pending validation"
                    });
                }
            }
        });
    } catch (e) {
        logger.error("Error in getProofStatus : " + e);
    }
});







/**
 * 
 * registerAuctionItem
 * 
 */
app.post('/registerAuctionItem', function(request, response){
    logger.info("registerAuctionItem");
    var auctionItemName = request.query.auctionItemName;
    logger.debug("auctionItemName : "+auctionItemName);
    web3.personal.unlockAccount(web3.eth.accounts[0], "");
    var txId = deployedAuctionContract['registerAuctionItem'](
        auctionItemName,{
            from:String(web3.eth.accounts[0]),
            gas: 4000000
        }
    );
    response.send({
        txId:txId
    });
});



/**
 * 
 * bidForItem
 */
app.post('/bidForItem', function (request, response) {
    logger.info("bidForItem");
    var auctionItemName = request.query.auctionItemName;
    var emailAddress = request.query.emailAddress;
    var biddingValue = request.query.biddingValue;

    logger.debug("emailAddress : " + emailAddress);
    logger.debug("biddingValue : " + biddingValue);
    logger.debug("auctionItemName : " + auctionItemName);

    //get wallet address for the emailAddress
    var userDetailsArray = deployedBalancedProofContract['getUserDetails'](emailAddress);
    logger.debug("userDetailsArray : " + userDetailsArray);
    var walletAddress = userDetailsArray[0];

    try {
        var auctionArray = deployedAuctionContract["getAuctionAuthData"](walletAddress);
        logger.debug("auctionArray : " + auctionArray);

        var transactionReceipt = web3.eth.getTransactionReceipt(auctionArray[1]);

        var logs = transactionReceipt.logs;
        logger.debug("transactionLog : " + JSON.stringify(logs));
        var logData = logs[0];
        let transactionData = SolidityCoder.decodeParams(["string"], logData.data.replace("0x", ""));

        if (transactionData != "Transaction successfully verified.") {

            response.send({
                txId: null,
                transactionStatus: transactionData,
                customerAddress: walletAddress
            });
        }


        logger.debug("unlocking wallet");
        web3.personal.unlockAccount(web3.eth.accounts[0], "");
        var bidTxId = deployedAuctionContract['bidForItem'](
            auctionItemName,
            emailAddress,
            biddingValue,
            walletAddress, {
                from: String(web3.eth.accounts[0]),
                gas: 4000000
            });

        logger.debug("bidTxId : " + bidTxId);

        response.send({
            txId: bidTxId,
            transactionStatus: transactionData,
            customerAddress: walletAddress
        });
    }catch (e) {
        logger.error("error in bidForItem : " + e);
        var responseData = "Verification pending";
        response.send({
            txId:null,
            transactionStatus: responseData,
            customerAddress: walletAddress
        })
    }
});

/**
 * getHighestBidder
 */
app.get('/getHighestBidder', function(request, response){
    logger.info("getHighestBidder");
    var auctionItemName = request.query.auctionItemName;
    var highestBidderInfo = deployedAuctionContract['getHighestBidder'](auctionItemName);
    logger.debug("highesBidderInfo : "+highestBidderInfo);
    var bidderAddress = highestBidderInfo[0];
    var bidderValue = highestBidderInfo[1];
    var bidderName = web3.toUtf8(highestBidderInfo[2]);
    response.send({
        bidderAddress:bidderAddress,
        bidderName:bidderName,
        bidderValue:bidderValue
    });
});


/**
 * getBidders
 * 
 */
app.get('/getBidders', function(request, response){
    logger.info("getBidders");
    var auctionItemName = request.query.auctionItemName;
    logger.debug("auctionItemName : "+auctionItemName);

    var bidderListRaw = deployedAuctionContract['getBidderList'](auctionItemName);
    var bidderList = [];
    var bidderAddressListRaw = bidderListRaw[0];
    var bidderNameListRaw = bidderListRaw[1];

    for(let index=0 ; index < bidderAddressListRaw.length; index++){
        let bidderObject = {
            bidderAddress:bidderAddressListRaw[index],
            bidderName:web3.toUtf8(bidderNameListRaw[index])
        }
        bidderList.push(bidderObject);
    }

    response.send({
        bidderList
    });
});


/**
 * getBidderInfo
 */
app.get('/getBidderInfo', function(request, response){
    logger.info("getBidderInfo");
    var bidderAddress = request.query.bidderAddress;
    var auctionItemName = request.query.auctionItemName;
    logger.debug("bidderAddress : "+bidderAddress);
    logger.debug("auctionItemName : "+auctionItemName);

    var customerInfo = deployedAuctionContract['getBidderInfo'](auctionItemName, bidderAddress);

    var bidderInfo = {

        bidValue:customerInfo[0],
        bidStatus:customerInfo[1] 
    }

    response.send(bidderInfo);
});



/**
 * API to deploy verifier contract
 */
app.post('/deployVerifierContract', function(request, response){
    logger.debug("deployVerifierContract");
    if (!request.files)
    return response.status(400).send('No files were uploaded.');

    let contractFile = request.files.document;
    contractFile.mv(request.files.document.name, function(err){
        if(err){
            return response.status(500).send(err);
        }

        var solidityFilePath = request.files.document.name;
        var solidityJsonFile = "Verifier.json"
        var contractName = "Verifier";
        var gasRequired = "30000000";
        var accountAddress = web3.eth.accounts[0];
        var accountPassword = "";
        var rpcAddress = "localhost";
        var rpcPort = "22002";
        var contractAddressFilePath = "VerifierContractAddress.json";

        //deploy contract
        deployContract.deployContract(solidityFilePath,solidityJsonFile,contractName, gasRequired, accountAddress, accountPassword,
            rpcAddress, rpcPort, contractAddressFilePath);
        logger.debug("after wait");
        //logger.debug("contract address : "+contractAddress);
        setTimeout(function(){
            logger.debug("reloading verifier contract : ");
            reloadVerifierContract();
            logger.debug("starting event listener");
            startVerifierEvents();
            response.send({
                message:"contract deployed"
            });
        },25000);
    });
});



/**
 * getTxnsForAuctionItem
 */
app.get('/getTxnsForAuctionItem', function(request, response){
    logger.info("getTxnsForAuctionItem");
    var auctionItemName = (request.query.auctionItemName).toLowerCase();
    
    auctiondb.collection(auctionItemName).find().toArray(function(err, result) {
        response.send(result);
    });
});


/**
 * 
 * getAllTxns
 */
app.get('/getAllTxns',function(request, response){
    logger.info("getAllTxns");

    var auctionList = [];
    auctiondb.listCollections().toArray(function(err, auctionItemList) {
        
        for (let index = 0; index < auctionItemList.length - 1 ; index++){
            let collectionName = auctionItemList[index];
            logger.debug("collectionName : "+JSON.stringify(collectionName));
            logger.debug("collectionName : "+collectionName.name);
            auctiondb.collection(collectionName.name).find().toArray(function(err, result){
                var auctionItem = {
                    auctionItemName:collectionName.name,
                    txnList:result
                }
                //logger.debug("result : "+result);
                auctionList.push(auctionItem);
            });
        }
    });

    setTimeout(function(){
        response.send(auctionList);
    },2000);
});




/**
 * 
 * @param {*} collectionName 
 * @param {*} data 
 */
function storeAuctionItemTx(collectionName, data, txLogRaw){
    logger.info("createAuctionItemCollection");

    let transactionId = data.transactionHash;
    let txLog = txLogRaw;
    let blockNumber = data.blockNumber;
    let block = web3.eth.getBlock(blockNumber);
    let timeStamp = block.timestamp;

    let record = {
        transactionId : transactionId,
        txLog : txLog,
        blockNumber : blockNumber,
        timeStamp : timeStamp
    }

    auctiondb.collection(collectionName).insertOne(record, function(err, res) {
        if (err) throw err;
        logger.debug("tx inserted into auctiondb ");
        //logger.debug(" : "+res);
    });
}




function storeProofStatus(emailAddress, proofStatus){
    logger.info("storeProofStatus");

    let record = {
        emailAddress : emailAddress,
        proofStatus : proofStatus
    }

    auctiondb.collection("proofstatus").insertOne(record, function(err, res){
        if(err) throw err;
        logger.debug("tx inserted into auctiondb");
        //logger.debug(res);
    });
}


function reloadVerifierContract(){
    verifierRawdata = fs.readFileSync('VerifierContractAddress.json');
    verifierContractData = JSON.parse(verifierRawdata);
    verifierContractAddress = verifierContractData.contract_address;
    verifierSource = fs.readFileSync("Verifier.json");
    verifierContract = JSON.parse(verifierSource)["contracts"];
    verifierABI = JSON.parse(verifierContract["AuctionhouseVerifier.sol:Verifier"].abi);
    deployedVerifierContract = web3.eth.contract(verifierABI).at(String(verifierContractAddress));
}


function startVerifierEvents(){

    //verified event
    verifiedEvent = deployedVerifierContract.Verified({}, {
        fromBlock: 'latest',
        toBlock: 'latest'
    });
    verifiedEvent.watch(function (error, result) {
        logger.debug("verifierEvent : " + JSON.stringify(result));
    });

    //unverified event
    unverifiedEvent = deployedVerifierContract.Unverified({}, {
        fromBlock: 'latest',
        toBlock: 'latest'
    });
    unverifiedEvent.watch(function (error, result) {
        logger.debug("unVerifierEvent : " + JSON.stringify(result));
    });
}




//assuming app is express Object.
app.get('/index',function(req,res){
	res.sendFile(path.join(__dirname+'/UI/index.html'));
});


app.use('/', function (req, res) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
    var message ={
        message:"API service for Marsh on Quorum"
    }
    res.send(message);
});

/**
 * application configuration
 */
app.listen(appPort, appIp,function () {
	logger.info("Auctionhouse API started and serving at IP : "+appIp+", Port : "+appPort);
});