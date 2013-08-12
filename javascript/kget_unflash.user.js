// ==UserScript==
// @name        kget_noflash
// @namespace   http://sorah.jp/
// @description remove flash, and javascript will retrieve lyric for you.
// @include     http://lyric.kget.jp/*
// ==/UserScript==

window.addEventListener("load", function() {
  var embed = document.querySelector(".pane noscript");
  var sn = embed.innerHTML.match(/&lt;param name="movie" value="http:\/\/lyric\.kget\.jp\/iframe\/lyric\.swf\?(sn=.+?)"/)[1];
  var lyric_url = "http://lyric.kget.jp/iframe/sendlyric.aspx?" + sn;

  var pane = embed.parentElement;
  pane.innerHTML = "";

  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function(e) {
    if (xhr.readyState == 4) {
      var lyric_element = document.createElement("div");
      lyric_element.innerHTML = xhr.responseText.replace(/^lyric=/,'').replace(/\r?\n/g,'<br>');
      pane.appendChild(lyric_element);
    }
  };
  xhr.open("GET", lyric_url)
});
