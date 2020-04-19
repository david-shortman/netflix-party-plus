'use strict';

//////////////////////////////////////////////////////////////////////////
// Google Analytics                                                     //
//////////////////////////////////////////////////////////////////////////

// inject Google Analytics
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-71812070-2']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = 'https://ssl.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();

//////////////////////////////////////////////////////////////////////////
// Autoupdate                                                           //
//////////////////////////////////////////////////////////////////////////
chrome.runtime.onUpdateAvailable.addListener(function(details) {
  // console.log("updating to version " + details.version);
  _gaq.push(['_trackEvent', 'auto-update ->' + details.version, 'clicked']);
  chrome.runtime.reload();
});

//////////////////////////////////////////////////////////////////////////
// User Event logging                                                   //
//////////////////////////////////////////////////////////////////////////

// send over permId when sending events over to SQL data server
var permId;
var recentlyUpdated;
chrome.storage.local.get(null, function(data) {
  if(data.userId) {
    permId = data.userId;
  }
  if(data.recentlyUpdated) {
    recentlyUpdated = data.recentlyUpdated;
  }
});

// log events
function logEvent(eventType, sessionId) {
  try {
    if(permId && recentlyUpdated) {
      var data = {
        userId: permId,
        eventType: eventType,
        sessionId: sessionId
      }

      console.log("event: " + JSON.stringify(data));

      var xmlhttp = new XMLHttpRequest();   // new HttpRequest instance 
      xmlhttp.open("POST", "https://data2.netflixparty.com/log-event");
      xmlhttp.setRequestHeader("Content-Type", "application/json");
      xmlhttp.send(JSON.stringify(data));
    }    
  } catch(e) {
    console.log("log event error");
  }
}




//////////////////////////////////////////////////////////////////////////
// Popup Logic                                                          //
//////////////////////////////////////////////////////////////////////////

var $ = jQuery;
$(function() {
  var getURLParameter = function(url, key) {
    var searchString = '?' + url.split('?')[1];
    if (searchString === undefined) {
      return null;
    }
    var escapedKey = key.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
    var regex = new RegExp('[?|&]' + escapedKey + '=' + '([^&]*)(&|$)');
    var match = regex.exec(searchString);
    if (match === null) {
      return null;
    }
    return decodeURIComponent(match[1]);
  };

  // get the current tab
  chrome.tabs.query({
      active: true,
      currentWindow: true
    }, function(tabs) {

      var contentScript;
      var serverIdFromUrl = getURLParameter(tabs[0].url, 'npServerId', 1);
      // TODO: fix logic

      if(!serverIdFromUrl) {
        // in v1 default content script here is going to be the old content script, connecting to s1
        // in v2 default content script here is going to be the new content script, connecting to s2
        contentScript = 'content_script.js'
      } else {
          if(serverIdFromUrl === 's1') {
            contentScript = 'content_script.js'
          } else {
            contentScript = 'content_script.js';    
          }        
      }

      // error handling
      var showError = function(err) {
        $('.some-error').removeClass('hidden');
        $('.no-error').addClass('hidden');
        $('#error-msg').html(err);
      };

      $('#close-error').click(function() {
        $('.no-error').removeClass('hidden');
        $('.some-error').addClass('hidden');
      });

      // set up the spinner
      var startSpinning = function() {
        $('#control-lock').prop('disabled', true);
        $('#create-session').prop('disabled', true);
        $('#leave-session').prop('disabled', true);
      };

      var stopSpinning = function() {
        $('#control-lock').prop('disabled', false);
        $('#create-session').prop('disabled', false);
        $('#leave-session').prop('disabled', false);
      };

      // send a message to the content script
      var sendMessage = function(type, data, callback) {
        startSpinning();
        chrome.tabs.executeScript(tabs[0].id, {
          file: contentScript
        }, function() {


          chrome.tabs.sendMessage(tabs[0].id, {
            type: type,
            data: data
          }, function(response) {
            stopSpinning();
            if (response.errorMessage) {
              showError(response.errorMessage);
              return;
            }
            if (callback) {
              callback(response);
            }
          });
        });
      };


      // send a message to the content script
      var sendTestMessage = function(type, data, callback) {
        chrome.tabs.sendMessage(tabs[0].id, {
          type: type,
          data: data
        }, function(response) {
          chrome.extension.getBackgroundPage().console.log(JSON.stringify(response));
          if (callback) {
            callback(response);
          }
        });
      };

      // // connected/disconnected state
      // var showConnected = function(sessionId) {
      //   var urlWithSessionId = tabs[0].url.split('?')[0] + '?npSessionId=' + encodeURIComponent(sessionId);
      //   $('.disconnected').addClass('hidden');
      //   $('.connected').removeClass('hidden');
      //   $('#show-chat').prop('checked', true);
      //   $('#share-url').val(urlWithSessionId).focus().select();
      // };

      // connected/disconnected state
      var showConnected = function(sessionId, defaultServer) {
        var urlWithSessionId;
        var serverIdFromUrl = getURLParameter(tabs[0].url, 'npServerId', 1);
        // console.log(defaultServer);
        var testDefaultServer = defaultServer ? defaultServer : 's2';
        // console.log('show connected default server: ' + testDefaultServer);
        if(serverIdFromUrl) {
          urlWithSessionId = tabs[0].url.split('?')[0] + '?npSessionId=' + encodeURIComponent(sessionId) + '&npServerId=' + encodeURIComponent(serverIdFromUrl);
        } else {
          // TODO: change to aws in next version
          // TOOD: change to s2 in next version
          urlWithSessionId = tabs[0].url.split('?')[0] + '?npSessionId=' + encodeURIComponent(sessionId) + '&npServerId=' + testDefaultServer;
        }

        $('.disconnected').addClass('hidden');
        $('.connected').removeClass('hidden');
        $('#show-chat').prop('checked', true);
        $('#share-url').val(urlWithSessionId) .focus().select();
      };

      var showDisconnected = function() {
        $('.disconnected').removeClass('hidden');
        $('.connected').addClass('hidden');
        $('#control-lock').prop('checked', false);
      };

      // get the session if there is one
      sendMessage('getInitData', {
        version: chrome.app.getDetails().version
      }, function(initData) {
        // parse the video ID from the URL
        var videoId = parseInt(tabs[0].url.match(/^.*\/([0-9]+)\??.*/)[1]);
        var videoDomId = null;

        if(initData.videoDomId) {
          videoDomId = initData.videoDomId;
        }


        // initial state
        if (initData.errorMessage) {
          showError(initData.errorMessage);
          return;
        }
        if (initData.sessionId === null) {
          var sessionIdFromUrl = getURLParameter(tabs[0].url, 'npSessionId');
          if (sessionIdFromUrl) {
            sendMessage('joinSession', {
              sessionId: sessionIdFromUrl.replace(/^\s+|\s+$/g, '').toLowerCase(),
              videoId: videoId
            }, function(response) {
              showConnected(sessionIdFromUrl);
              _gaq.push(['_trackEvent', 'join-session', 'clicked']);
              logEvent('join-session', sessionIdFromUrl);
            });
          }
        } else {
          showConnected(initData.sessionId, initData.defaultServer);
        }

        $('#show-chat').prop('checked', initData.chatVisible);

        // listen for clicks on the "Create session" button
        $('#create-session').click(function() {
          sendMessage('createSession', {
            controlLock: $('#control-lock').is(':checked'),
            videoId: videoId
          }, function(response) {
            showConnected(response.sessionId, response.defaultServer);
            _gaq.push(['_trackEvent', 'create-session', 'clicked']);
            logEvent('create-session', response.sessionId);
          });
        });

        // listen for clicks on the "Leave session" button
        $('#leave-session').click(function() {
          sendMessage('leaveSession', {}, function(response) {
            showDisconnected();
          });
        });

        // listen for clicks on the "Show chat" checkbox
        $('#show-chat').change(function() {
          sendMessage('showChat', { visible: $('#show-chat').is(':checked') }, null);
        });

        // listen for clicks on the share URL box
        $('#share-url').click(function(e) {
          var sessionIdFromShareUrl = getURLParameter($('#share-url').val(), 'npSessionId', 1);
          var defaultServerFromShareUrl = getURLParameter($('#share-url').val(), 'npServerId', 1);
          if(sessionIdFromShareUrl) showConnected(sessionIdFromShareUrl, defaultServerFromShareUrl);

          e.stopPropagation();
          e.preventDefault();
          $('#share-url').select();
        });

        // listen for clicks on the "Copy URL" link
        $('#copy-btn').click(function(e) {
          console.log('click');
          var sessionIdFromShareUrl = getURLParameter($('#share-url').val(), 'npSessionId', 1);
          var defaultServerFromShareUrl = getURLParameter($('#share-url').val(), 'npServerId', 1);
          if(sessionIdFromShareUrl) showConnected(sessionIdFromShareUrl, defaultServerFromShareUrl);
          e.stopPropagation();
          e.preventDefault();
          $('#share-url').select();
          document.execCommand('copy');
        });
      });
    }
  );
});
