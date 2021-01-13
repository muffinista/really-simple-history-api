historyData = {
  host: "https://history.muffinlabs.com/",
	load: function(options) {
		var callback, month, day, host;
    var path = '/date';

    host = this.host;
    
		if ( typeof(options) == "function" ) {
			callback = options;
		}
		else if ( typeof(options) == "object" ) {
			callback = options.callback;
	  }

    if ( typeof(options.month) === "undefined" ) {
      options.month = new Date().getMonth() + 1;
    }

    if ( typeof(options.day) === "undefined" ) {
      options.day = new Date().getDate();
    }

		month = options.month;
		day = options.day;
    path = path + '/' + month + '/' + day;

    if ( options.host !== undefined ) {
      host = options.host;
    }

    return fetch(host + path, {
      headers: {
        'Content-Type': 'application/json'
      },
    })
      .then(response => response.json())
      .then((data) => {
        if ( callback ) {
          callback(data);
        }
        return data;
      });
	}
}
