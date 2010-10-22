Really Simple History API
=========================


What is it?
-----------
I wanted to write a 'this day in history' twitter bot, which posts events which 
happened on this day.  There's a few people on Twitter doing this already, but I
am lazy and wanted to automate it.

Luckily, [Wikipedia](http://en.wikipedia.org/wiki/List_of_historical_anniversaries) has 
entries for each day of the year.  I wrote a parser to turn this into JSON data, and a very
simple Sinatra app to spit out that data for any given day.

Just for kicks, I wrote a pretty simple JS interface as well.  You can see it in action on
the [Today's History](http://history.muffinlabs.com/today) page.


How To Use
----------
* Get today's history in JSON format at [/date](http://history.muffinlabs.com/date)
* Get another day's history in JSON at <strong>/date/month/day</strong> where month and day are numbers. For example, [/date/2/14](http://history.muffinlabs.com/date/2/14) to get the history for February 14th.
* The data is split into births, deaths, and events.  Each element is a hash with one 'text' field.  I might add a URL or some other fields later.

* Take a look at [the API javascript](http://history.muffinlabs.com/api.js) or the [history ticker](http://history.muffinlabs.com/today) to see the code in use.
