$(document).ready(function(){
	var ipAdd=ipAddress();
	var port=portNo();

	var tempLists=[];
	var dataSets=[];


	$.get("http://"+ipAdd+":"+port+"/getHighestBidder?auctionItemName=starryNight", function(response){

		document.getElementById('highestBid').innerHTML="Highest Bid till now has been placed by: "+response.bidderName+" at :  $"+response.bidderValue;

	


} );




	$.get("http://"+ipAdd+":"+port+"/getBidders?auctionItemName=starryNight", function(response){
		// alert(JSON.stringify(response));
	
		$.each(response.bidderList, function(i, item) {
		
			
				tempLists.push(i+1,item.bidderName,item.bidderAddress);
				
				dataSets.push(tempLists);
				tempLists=[];

				//alert(dataSet);		               

			
		});

		var table =	$('#allBids').dataTable( {
			//"order": [],
			//aaSorting: [[5, 'desc']],
			data: dataSets,

			columns: [
				{ title: "SNo" },
				{ title: "Bidder" },
				{ title: "Address" }
				]
		} );
	} );
});
