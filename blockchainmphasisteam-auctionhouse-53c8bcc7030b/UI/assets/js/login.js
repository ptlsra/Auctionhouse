var ipAdd=ipAddress();
var port=portNo();


//alert(ipAdd);
localStorage.setItem("transactionId",0);
  


$("#loginButton").click(function(){
	
	 var userName=$("#userName").val();
	
	
	
    

$.ajax({
	
    dataType:"json",
    contentType: 'application/json; charset=UTF-8',
    url: "http://"+ipAdd+":"+port+"/getUserInfo?emailAddress="+userName,
    type:"GET",
    global:false,
    async:false, 
    success: function(result){
	//alert(result);
	
       
        var status=result.isRegistered;
        //alert(message);
        if(status==false){
        	
        	 document.getElementById("txId").innerHTML = "You are not registered.";
             $("#myModal").modal();
             setTimeout(function(){ 
                 
                 window.location.href="index.html";
          
              }, 2000);
        	 
        }
        
        else{
       	 document.getElementById("txId").innerHTML = "Welcome to Auction House Portal.Please Wait while you are being redirected.";
         $("#myModal").modal();
         // Store
         customerAddress=result.customerAddress;
            localStorage.setItem("customerAddress", customerAddress);
            localStorage.setItem("emailAddress", userName);
            
         setTimeout(function(){ 
             
             window.location.href="auction.html";
      
          }, 1000);
        	
        }        
       
	}
});

});
