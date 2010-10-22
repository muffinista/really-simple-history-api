historyData = {
	// jx -- http://www.openjs.com/scripts/jx/
	jx : {getHTTPObject:function(){var A=false;if(typeof ActiveXObject!="undefined"){try{A=new ActiveXObject("Msxml2.XMLHTTP")}catch(C){try{A=new ActiveXObject("Microsoft.XMLHTTP")}catch(B){A=false}}}else{if(window.XMLHttpRequest){try{A=new XMLHttpRequest()}catch(C){A=false}}}return A},load:function(url,callback,format){var http=this.init();if(!http||!url){return }if(http.overrideMimeType){http.overrideMimeType("text/xml")}if(!format){var format="text"}format=format.toLowerCase();var now="uid="+new Date().getTime();url+=(url.indexOf("?")+1)?"&":"?";url+=now;http.open("GET",url,true);http.onreadystatechange=function(){if(http.readyState==4){if(http.status==200){var result="";if(http.responseText){result=http.responseText}if(format.charAt(0)=="j"){result=result.replace(/[\n\r]/g,"");result=eval("("+result+")")}if(callback){callback(result)}}else{if(error){error(http.status)}}}};http.send(null)},init:function(){return this.getHTTPObject()}},
	data : {},
	load : function(options) {
		var callback, month, day;
		if ( typeof(options) == "function" ) {
			callback = options;
		}
		else if ( typeof(options) == "object" ) {
			callback = options.callback;
			month = options.month;
			day = options.day;
		}

		this.jx.load('/date',function(d) {
				var tmp = eval('(' + d + ')');
				historyData.data = tmp.data;
				historyData.url = tmp.url;
				historyData.date = tmp.date;
				if ( typeof(callback) == "function" ) {
					callback(historyData.data);
				}
			});
	}
}