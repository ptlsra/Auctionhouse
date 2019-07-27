$(document).ready(function(){
	var ipAdd=ipAddress();
	var port=portNo();

	var tempLists=[];
	var dataSets=[];





	$.get("http://"+ipAdd+":"+port+"/getAllTxns", function(response){
		// alert(JSON.stringify(response));
	//console.log(JSON.stringify(response))
		$.each(response[0].txnList, function(i, item) {
		
			
			var txId=item.transactionId;
			var auctionItemName=item.txLog.auctionItemName;
			var blockNumber=item.blockNumber;
			var timeStamp=item.timeStamp;

			
		//	var unixtimestamp = timeStamp.toString().slice(0,-);
			var unixtimestamp = item.timeStamp;
			// Months array
			var months_arr = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

			// Convert timestamp to milliseconds
			var date = new Date(unixtimestamp*1000);

			// Year
			var year = date.getFullYear();

			// Month
			var month = months_arr[date.getMonth()];

			// Day
			var day = date.getDate();

			// Hours
			var hours = date.getHours();

			// Minutes
			var minutes = "0" + date.getMinutes();

			// Seconds
			var seconds = "0" + date.getSeconds();

			// Display date time in MM-dd-yyyy h:m:s format
			var convdataTime = month+'-'+day+'-'+year+' '+hours + ':' + minutes.substr(-2) + ':' + seconds.substr(-2);

				tempLists.push(i+1,'<a href="#" data-toggle="tooltip" title='+txId+'>'+txId.substr(0,20)+'...',auctionItemName,blockNumber,convdataTime);
				
				dataSets.push(tempLists);
				tempLists=[];

				//alert(dataSet);		               

			
		});

		var table =	$('#allTx').dataTable( {
			//"order": [],
			//aaSorting: [[5, 'desc']],
			data: dataSets,

			columns: [
				{ title: "SNo" },
				{ title: "TxId" },
				{ title: "Auction Name" },
				{ title: "Block Number" },
				{ title: "TimeStamp" },

				]
		} );
	} );
});
