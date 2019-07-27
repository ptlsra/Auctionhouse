/**
 * Script to drop mongodb database
 */
var log4js = require('log4js');
var logger = log4js.getLogger('dropDatabase.js');
var MongoClient = require('mongodb').MongoClient;
var fs = require("fs");

/**
 * Read app configuration
 */
let configRawData = fs.readFileSync('config.json');
let configData = JSON.parse(configRawData);

var mongodb_ip = configData.mongodb_ip;
var mongodb_port = configData.mongodb_port;
logger.level = configData.logLevel;


/**
 * method to drop multiple databases
 * @param {JSONArray} databaseList 
 */
function dropDatabases(databaseList){
    logger.debug("dropDatabases");
    //loop through databaseList and drop
    for(let index = 0; index < databaseList.length; index++){
        var databaseObject  = databaseList[index];
        dropDatabase(databaseObject);
    }
}

/**
 * method to drop single database
 * @param {JSONObject} database
 */
function dropDatabase(databaseObject) {
    logger.info("dropDatabase");
    try {
        logger.debug("database : " + JSON.stringify(databaseObject));
        logger.debug("databaseName : "+databaseObject.databaseName);
        logger.debug("collectionList : "+databaseObject.collectionList);

        //loop through the collectionList and delete
        for(let index = 0 ; index < databaseObject.collectionList.length; index++){
            logger.info("dropping collection : "+databaseObject.collectionList[index]);
            drop(databaseObject.databaseName, databaseObject.collectionList[index]);
        }

    } catch (e) {
        logger.error("Error in dropDatabase : " + e);
    }
}

/**
 * 
 * @param {databaseName} databaseName 
 * @param {collectionName} collectionName 
 */
function drop(databaseName, collectionName){
    logger.info("drop");
    try{
        logger.debug("databaseName : "+databaseName);
        logger.debug("mongoIP : "+mongodb_ip);
        logger.debug("mongoPort : "+mongodb_port);

        //connect to mongodb database
        var databaseUrl = "mongodb://"+mongodb_ip+":"+mongodb_port+"/"+databaseName;
        logger.debug("databaseUrl : "+databaseUrl);

        MongoClient.connect(databaseUrl, function(err, db) {
            //delete collection
            db.collection(collectionName).drop(function(err, delOK) {
                if (err) throw err;
                if (delOK) console.log("Collection deleted");
                logger.warn("Closing database connection");
                db.close();
              });
        });
    }catch(e){
        logger.error("Error in drop : "+e);
    }
}
/*
var databaseO = {
    databaseName : "banktxndb",
    collectionList : [
        "customers"
    ]
}
*/

drop("bankdb", "customers");



/*
module.exports.dropDatabases = dropDatabases;
module.exports.dropDatabase = dropDatabase;
*/
