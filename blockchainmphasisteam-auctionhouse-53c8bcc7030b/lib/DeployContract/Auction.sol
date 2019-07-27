pragma solidity ^0.4.25;

contract Auction{
    
    struct AuctionItem{
        string itemName;
        //uint bidders;
        mapping(address => bool) bidStatus;
        mapping(address => uint) bidValue;
        mapping(address => bytes32) bidderName;
        address[] bidders;
        address highestBidder;
    }

    struct AuctionAuth{
        address customerAddress;
        string txId; //txId
        uint256 validity; //unix timestamp
    }
    
    mapping(address => AuctionAuth) auctionAuth;
    mapping(string => AuctionItem) auctionItem;
    
    
    event RegisterAuctionItem(string auctionItemName);
    event BidForItem(string auctionItemName, address bidderAddress, bytes32 bidderName, uint value);
    
    function registerAuctionItem(string auctionItemName)public{
        address[] memory temp;
        auctionItem[auctionItemName] = AuctionItem({
            itemName:auctionItemName,
            bidders:temp,
            highestBidder:0
        });
       emit RegisterAuctionItem(auctionItemName);
    }
    
    function getAuctionItemBidders(string auctionItemName)public view returns(address[]){
        return (auctionItem[auctionItemName].bidders);
    }
    
    
    function getBidderList(string auctionItemName)public view returns(address[], bytes32[]){
        bytes32[]  bidderNameList;
        //bool[]  bidStatusArray;
        
        for(uint index = 0 ; index < auctionItem[auctionItemName].bidders.length; index++){
            address bidderAddress = auctionItem[auctionItemName].bidders[index];
            bidderNameList.push(auctionItem[auctionItemName].bidderName[bidderAddress]);
           // bidStatusArray.push(auctionItem[auctionItemName].bidStatus[bidderAddress]);
        }
        return (auctionItem[auctionItemName].bidders, bidderNameList);
    }
    
    
    function getBidderInfo(string auctionItemName, address bidderAddress)public view returns(uint, bool){
        return (auctionItem[auctionItemName].bidValue[bidderAddress], auctionItem[auctionItemName].bidStatus[bidderAddress]);
    }
    
    
    function bidForItem(string auctionItemName,bytes32 bidderName, uint bidValue, address senderAddress)public payable{

        if (auctionItem[auctionItemName].bidStatus[senderAddress] == true){
            revert();
        }
        auctionItem[auctionItemName].bidders.push(senderAddress);
        auctionItem[auctionItemName].bidStatus[senderAddress] = true;
        auctionItem[auctionItemName].bidValue[senderAddress] = bidValue;
        auctionItem[auctionItemName].bidderName[senderAddress] = bidderName;
        uint highestBidValue = bidValue;
        
        for(uint index = 0 ; index < auctionItem[auctionItemName].bidders.length; index++){
            address bidderAddress = auctionItem[auctionItemName].bidders[index];
            if (auctionItem[auctionItemName].bidValue[bidderAddress] >= highestBidValue){
                
                highestBidValue = auctionItem[auctionItemName].bidValue[bidderAddress];
                auctionItem[auctionItemName].highestBidder = bidderAddress;
            }
        }
        
        emit BidForItem(auctionItemName, senderAddress, bidderName, bidValue);
    }
    
    function getHighestBidder(string auctionItemName)public view returns (
        address,
        uint,
        bytes32
        ){
            return(auctionItem[auctionItemName].highestBidder, 
            auctionItem[auctionItemName].bidValue[auctionItem[auctionItemName].highestBidder],
            auctionItem[auctionItemName].bidderName[auctionItem[auctionItemName].highestBidder]
            );
    }
    
    
    function setAuctionAuth(address customerAddress, string txId, uint256 validity) public {
        auctionAuth[customerAddress] = AuctionAuth({
            customerAddress:customerAddress,
            txId : txId,
            validity : validity
        });
    }
    
    function getAuctionAuthData(address customerAddress)public view returns(
        address,
        string,
        uint256
        ){
        return (
            auctionAuth[customerAddress].customerAddress,
            auctionAuth[customerAddress].txId,
            auctionAuth[customerAddress].validity
        );
    }
}