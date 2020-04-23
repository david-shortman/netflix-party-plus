'use strict';

// log events
function logEvent(eventType) {
  var numTries = 0;
  var permId, recentlyUpdated;
  var logEventInterval = setInterval(function() {
    try {
      if(numTries > 5) {
        clearInterval(logEventInterval);
      }

      chrome.storage.local.get(null, function(data) {
        if(data.userId) {
          permId = data.userId;
        }
        if(data.recentlyUpdated) {
          recentlyUpdated = data.recentlyUpdated;
        }
      });


      // only send events if recent update
      if(permId && recentlyUpdated) {
        var data = {
          userId: permId,
          eventType: eventType,
        }

        console.log("event: " + JSON.stringify(data));

        var xmlhttp = new XMLHttpRequest();   // new HttpRequest instance 
        xmlhttp.open("POST", "https://data2.netflixparty.com/log-event");
        xmlhttp.setRequestHeader("Content-Type", "application/json");
        xmlhttp.send(JSON.stringify(data));
        
        clearInterval(logEventInterval);
      } else {
        numTries = numTries + 1;
      }   
    } catch (e) {
      console.log("log event error");
    }
  }, 5000);
}

chrome.runtime.onInstalled.addListener(function(details){
    if(details.reason == "install"){
        var thisVersion = chrome.runtime.getManifest().version;
        chrome.tabs.create({'url': "https://www.netflixparty.com/tutorial"}, function() {
          console.log('created new tab after install');
        });
    }
});

//////////////////////////////////////////////////////////////////////////
// Autoupdate                                                           //
//////////////////////////////////////////////////////////////////////////
chrome.runtime.onUpdateAvailable.addListener(function(details) {
  chrome.runtime.reload();
});

//////////////////////////////////////////////////////////////////////////
// User Authentication                                                  //
//////////////////////////////////////////////////////////////////////////

try {
  function validateId(id) {
    return typeof id === 'string' && id.length === 16;
  }

  // Ensure that chrome extension has unique userid
  function setUserId() {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (xhr.readyState == XMLHttpRequest.DONE) {
        var userId = xhr.responseText;
        if(validateId(userId)) {
          chrome.storage.local.set({'userId': userId, 'recentlyUpdated': true}, function() {
            console.log('Settings saved');
          });
          chrome.runtime.setUninstallURL("https://www.netflixparty.com/uninstall?userId=" + userId);
        }
      }
    }
    xhr.open('GET', 'https://data2.netflixparty.com/create-userId', true);
    xhr.send(null);
  }

  // Ensure that chrome extension resets unique userid
  function resetUserId(oldUserId) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (xhr.readyState == XMLHttpRequest.DONE) {
        var userId = xhr.responseText;
        if(validateId(userId)) {
          chrome.storage.local.set({'userId': userId, 'oldUserId': oldUserId, 'recentlyUpdated': true}, function() {
            console.log('Settings saved');
          });
          chrome.runtime.setUninstallURL("https://www.netflixparty.com/uninstall?userId=" + userId);
        }
      }
    }
    xhr.open('GET', 'https://data2.netflixparty.com/create-userId', true);
    xhr.send(null);
  }

  chrome.storage.local.get(null, function(data) {
    // message('Settings retrieved', items);
    if(!data.userId) {
      console.log("userId undefined in local storage -> now setting")
      setUserId();
    } else {
      if(!data.recentlyUpdated) {
        console.log("userId undefined in local storage -> now setting")
        resetUserId(data.userId);
      } else {
        console.log("chrome storage local has user id: " + data.userId);
        chrome.runtime.setUninstallURL("https://www.netflixparty.com/uninstall?userId=" + data.userId);
      }
    }
  });
} catch(e) {
  console.log("user auth error");
}

chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {
    console.log(sender.tab ? "from a content script:" + sender.tab.url : "from the extension");
    if (request.summary) {
      var xmlhttp = new XMLHttpRequest();   // new HttpRequest instance 
      xmlhttp.open("POST", "https://data2.netflixparty.com/log-summary", true);
      xmlhttp.setRequestHeader("Content-Type", "application/json");
      xmlhttp.send(JSON.stringify(request.summary));

      sendResponse({farewell: "goodbye"});
    }
  }
);

//////////////////////////////////////////////////////////////////////////
// Background Logic                                                     //
//////////////////////////////////////////////////////////////////////////

// only load for URLs that match www.netflix.com/watch/*
chrome.runtime.onInstalled.addListener(function(details) {
  chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
    chrome.declarativeContent.onPageChanged.addRules([{
      conditions: [
        new chrome.declarativeContent.PageStateMatcher({
          pageUrl: {
            hostContains: '.netflix.',
            pathPrefix: '/watch/',
            schemes: ['http', 'https']
          }
        })
      ],
      actions: [new chrome.declarativeContent.ShowPageAction()]
    }]);
  });
});