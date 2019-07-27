

var ipAdd=ipAddress();
var port=portNo();
//alert(ipAdd);




var customerAddress=localStorage.getItem("customerAddress");
$.get("http://"+ipAdd+":"+port+"/getBidders?auctionItemName=starryNight", function(responseval){
    //alert(responseval);
    var reclength=responseval.bidderList.length;
   
    document.getElementById("bid").innerHTML = "Number of Bidders :"+reclength;
    


});

$.get("http://"+ipAdd+":"+port+"/getBidderInfo?auctionItemName=starryNight&bidderAddress="+customerAddress, function(responseinfo){
   // alert(JSON.stringify(responseinfo));
   
    var status=responseinfo.bidStatus;

    if(status==true){
        $('#placeBid').hide();

      // $('#done').show();
     
     var textval='You have placed bid at $'+ responseinfo.bidValue+' for this product';
   // $('#done').val("You have placed bid at $"+ responseinfo.bidValue+" for this product.");
   $('#done').attr('value', textval);
   $("#done").html(textval);
    //    document.getElementById("done").value = "You have placed bid at $"+ responseinfo.bidValue+" for this product.";

       // document.getElementById("done").display = 'block';

    }
    else{
        $('#done').hide();
        $('#placeBid').show();
    //    document.getElementById("placeBid").display = 'block';
      //  document.getElementById("done").display.visibility = 'hidden';

       // $("#placeBid").show();
    }



});
var emailAddress=localStorage.getItem("emailAddress");
$("#userName").val(emailAddress);



$("#placeBid").click(function(){
    $("#bidModal").modal();

    
});


$("#placeBidConfirm").click(function(){
    $("#bidModal").hide();

    var userName=$("#userName").val();
    var biddingAmount=$("#biddingAmount").val();

    
    http://172.21.80.81:5500/bidForItem?auctionItemName=OVEN&emailAddress=alicesmith@gmail.com&biddingValue=50000 
    $.ajax({
	
        dataType:"json",
        contentType: 'application/json; charset=UTF-8',
        url: "http://"+ipAdd+":"+port+"/bidForItem?auctionItemName=starryNight&emailAddress="+userName+"&biddingValue="+biddingAmount, //replace api
        type:"POST",
        global:false,
        async:false, 
        success: function(result){
        //alert(result);
        
           
                document.getElementById("txId").innerHTML = result.txId;
               
    
             $("#myModal").modal();
             setTimeout(function(){ 
                 
                 window.location.href="auction.html";
          
              }, 1000);
                
             
           
        }
    });
    
});

