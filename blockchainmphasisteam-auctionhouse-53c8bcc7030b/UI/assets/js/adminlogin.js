
//alert(ipAdd);
localStorage.setItem("transactionId",0);
  


$("#adminLogin").click(function(){
	
	 var userName=$("#userName").val();
	
	

       
       
        if(userName=='admin'){
        	
        	
             setTimeout(function(){ 
                 
                 window.location.href="adminDashboard.html";
          
              }, 1500);
        	 
        }
        
        else{
         $("#myModal").modal();
         // Store
       
            
         setTimeout(function(){ 
             
             window.location.href="adminLogin.html";
             document.getElementById("txId").innerHTML = "Incorrect Credentials. Please try again.";
          }, 1000);
        	
        }        
       
	
});
