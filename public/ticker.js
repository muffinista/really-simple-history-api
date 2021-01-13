var setupTicker = function() {
  // random array sort from
  // http://javascript.about.com/library/blsort2.htm
  var randOrd = function() { return(Math.round(Math.random())-0.5); }
  
  var getLocation = function(href) {
    var l = document.createElement("a");
    l.href = href;
    return l.protocol + "//" + l.host;
  };
  
  var shuffleList = function(ul) {
    for (var i = ul.children.length; i >= 0; i--) {
      ul.appendChild(ul.children[Math.random() * i | 0]);
    }
  };
  
  var setupAnimation = function(el) {
    el.classList.add("fade-in-and-out");
    el.addEventListener('animationend', () => {
      el.classList.remove("fade-in-and-out");
      setTimeout(function() {
        el.classList.add("fade-in-and-out");
        shuffleList(el);
      }, 100);
    });
  };
  
  var host = getLocation(document.getElementById("ticker").src);
  
  historyData.load({
    host: host,
    callback: function(d) {
      // randomly sort our data just for variety
      d.data.Births.sort(randOrd);
      d.data.Events.sort(randOrd);
      d.data.Deaths.sort(randOrd);
       
        
      document.querySelector("#today").innerHTML = "Today in History: " + d.date;
      let lm = document.querySelector("#learn-more");
      
      lm.innerHTML = d.date + " on Wikipedia";
      lm.href = d.url;
        
      let births = document.querySelector("#births");
      let deaths = document.querySelector("#deaths");
      let events = document.querySelector("#events");

      d.data.Births.forEach((b) => {
        let li = document.createElement('li');
        li.innerHTML = b.year + " - " + b.text;
        births.appendChild(li);
      });
      d.data.Deaths.forEach(function(b) {
        let li = document.createElement('li');
        li.innerHTML = b.year + " - " + b.text;
        deaths.appendChild(li);
      });
      d.data.Events.forEach(function(b) {
        let li = document.createElement('li');
        li.innerHTML = b.html;
        events.appendChild(li);
      });

      setupAnimation(events);
      setupAnimation(deaths);
      setupAnimation(births);
    }
  });
};

document.onreadystatechange = function() {
  if (document.readyState === 'complete') {
    setupTicker();
  }
};


