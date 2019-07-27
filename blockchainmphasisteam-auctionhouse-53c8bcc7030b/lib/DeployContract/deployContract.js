
// Nodejs code to deploy verifier.sol to blockchain and return contract address

const Web3 = require('web3');
var fs = require('fs');
var log4js = require('log4js');
var logger = log4js.getLogger('deployContract.js');
var exec = require('child_process').exec, child;
logger.level = "debug"

//read config.json
let configData = fs.readFileSync('config.json');
let config = JSON.parse(configData);



function printUsage(){
    logger.info("printUsage");
    console.log("");
    console.log("deployContract.js. Deploys solidity file and writes contract address to a json file");
    console.log("");
    console.log("USAGE : ");
    console.log("        node deployContract.js [ARGS]");
    console.log("ARGS : ");
    console.log("--help  - prints USAGE");
    console.log("args[1] - solidityFilePath");
    console.log("args[2] - solidityJsonFilePath");
    console.log("args[3] - contractName");
    console.log("args[4] - gasRequired");
    console.log("args[5] - fromAddress");
    console.log("args[6] - accountPassword");
    console.log("args[7] - rpcAddress");
    console.log("args[8] - rpcPort");
    console.log("args[9] - contractAddress.json FilePath");
}

const deployContract = function deployContract(solidityFilePath, solidityJsonFilePath, contractName, gasRequired, fromAddress, accountPassword, rpcAddress, rpcPort, contractAddressFilePath){

    logger.info("deployContract");
    logger.debug("solidityFilePath : "+solidityFilePath);
    logger.debug("gasRequired : "+gasRequired);
    logger.debug("fromAddress : "+fromAddress);
    logger.debug("rpcAddress : "+rpcAddress);
    logger.debug("rpcPort : "+rpcPort);
    logger.debug("contractAddressFilePath : "+contractAddressFilePath);


    //connect to web3 provider
    var web3 = new Web3(new Web3.providers.HttpProvider("http://"+rpcAddress+":"+rpcPort));
    logger.debug("Compiling solidity file ...");
    child = exec(config.bin_dir+'solc --evm-version homestead --optimize --combined-json abi,bin,interface '+solidityFilePath+' > '+solidityJsonFilePath, function (error, stdout, stderr) {
        logger.debug('Solidity File Compiled Successfully!');
        if (error !== null) {
            console.log('error in compiling solidity file : ' + error);
        }
    });
    child;

    logger.info("Solidity file compiled and saved in json file");
    setTimeout(deployNewContract, 10000);

    function deployNewContract(){
        logger.info("deployNewContract");
        logger.info(web3.eth.accounts);
        var fileData = fs.readFileSync(solidityJsonFilePath);
        //logger.debug("solidity JSON file data : "+fileData);
        var content = JSON.parse(fileData);
        logger.info(solidityFilePath);
        logger.info(contractName);
        var abi = content.contracts[solidityFilePath+":"+contractName].abi;
        logger.debug("ABI is : "+abi);

        var binary = content.contracts[solidityFilePath+":"+contractName].bin;

        var bin = '0x'+binary;
        console.log("Required BINARY is: "+bin);

        logger.debug("account is : "+fromAddress);
        logger.debug("Contract is going to be deployed at account : " + fromAddress);

        const Contract = web3.eth.contract(JSON.parse(abi));

        logger.debug("unlocking account : "+fromAddress);
        
        var unlockStatus = web3.personal.unlockAccount(fromAddress, accountPassword);
        logger.debug("unlock status : "+unlockStatus);

        Contract.new({
            from: fromAddress,
            data: bin,
            gas:  gasRequired
        },function(err, contract){
            if(err) logger.error(err);
                if(typeof contract.address !== 'undefined'){

                    logger.debug('Contract mined! contract address: ' + contract.address + ' transactionHash: ' + contract.transactionHash)
                    logger.debug("contract address : "+contract.address);

                    let jsonData = {
                        "contract_address":contract.address
                    }

                    logger.debug("writing contract address to json file ");
                    logger.debug(contractAddressFilePath);
                    fs.writeFileSync((contractAddressFilePath),JSON.stringify(jsonData));
                    return contract.address;
                    
                }
        });
    }


}



module.exports.deployContract = deployContract;

    //get command line arguments
    var cmdArgs = process.argv.slice(2);
    logger.debug("args : "+cmdArgs);
    //check args length ( should be 9. If not print usage)
    if(cmdArgs.length == 9){
       deployContract(cmdArgs[0], cmdArgs[1], cmdArgs[2], cmdArgs[3], cmdArgs[4], cmdArgs[5], cmdArgs[6], cmdArgs[7], cmdArgs[8]);
    }else{
        printUsage();
    }

