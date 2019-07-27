var ipAdd=ipAddress();
var port=portNo();


//alert(ipAdd);

var transactionId=localStorage.getItem("transactionId");
var emailAddress=localStorage.getItem("emailAddress");
var customerAddress=localStorage.getItem("customerAddress");


//alert(transactionId);
//$("#requestBid").html('Hello');
document.getElementById("custominfo").innerHTML = "You have logged in to Auction House as: "+emailAddress;


$.get("http://"+ipAdd+":"+port+"/getProofStatus?emailAddress="+emailAddress, function(proofStatus){

var proofStatusMessage=proofStatus.message;

if(proofStatusMessage=="proof not submitted"){
    $("#requestBid").html('You have not Submitted Proof.Click Here to Submit Proof and Request Bidding Access.');

}else{
    var proofStatusTx=proofStatus.status;
    if(proofStatusMessage=="proof submitted" && proofStatusTx=="pending validation"){
        $("#requestBid").html('You have Submitted Proof for this Bid.Please wait while we verify.');
    } else if(proofStatusMessage=="proof submitted" && proofStatusTx=="verification failed"){
        $("#requestBid").html('The Submitted Proof has failed to qualify for this bid');
    }else{

        $.get("http://"+ipAdd+":"+port+"/getBidderInfo?auctionItemName=starryNight&bidderAddress="+customerAddress, function(responseinfo){

            var status=responseinfo.bidStatus;

            if(status==true){
                $("#requestBid").html('You have successfully placed bid for this item.');
            }else{
                $("#requestBid").html('Proof has been submitted succesfully. View Info and place Bid.');
            }
    });
       

    }
}



$("#requestBid").click(function(){
    
    


	
	if (proofStatusMessage=="proof not submitted"){
    $("#proofModal").modal();
    }else{
        var proofStatusTx=proofStatus.status;


            if(proofStatusTx=="pending validation"){
           

                $("#pendingModal").modal();
               
            }else if(proofStatusTx=="verification failed"){
                $("#pendingModal").hide();
                $("#txFailModal").modal();
            }else{
                if(proofStatusTx=="verification successful"){
                    $("#txFailModal").hide();
                    $("#pendingModal").hide();
                    $("#verifyModal").modal();

                    
                }
            }
     

   
    }

});

});
    

$("#submitProof").click(function(){

  
    $("#proofModal").hide();
    $("#requestModal").modal();
    
$.ajax({
	
    dataType:"json",
    contentType: 'application/json; charset=UTF-8',
    url: "http://"+ipAdd+":"+port+"/submitForVerifyTx?emailAddress="+emailAddress, //replace api
    type:"POST",
    global:false,
    async:false, 
    success: function(result){
	//alert(result);
	
       
            document.getElementById("txId").innerHTML = result.transactionId;
            localStorage.setItem("transactionId",1);
            $("#requestModal").hide();
         $("#myModal").modal();
         setTimeout(function(){ 
             
             window.location.href="auction.html";
      
          }, 1000);
        	
         
       
	}
});

});




$("#resubmitProof").click(function(){

  
    $("#txFailModal").hide();
    $("#requestModal").modal();
$.ajax({
	
    dataType:"json",
    contentType: 'application/json; charset=UTF-8',
    url: "http://"+ipAdd+":"+port+"/submitForVerifyTx?emailAddress="+emailAddress, //replace api
    type:"POST",
    global:false,
    async:false, 
    success: function(result){
	//alert(result);
	
       
            document.getElementById("txId").innerHTML = result.transactionId;
            localStorage.setItem("transactionId",1);
            $("#requestModal").hide();
         $("#myModal").modal();
         setTimeout(function(){ 
             
             window.location.href="auction.html";
      
          }, 1000);
        	
         
       
	}
});

});




