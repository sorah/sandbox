// ==UserScript==
// @name        hateb_avoid_cussion
// @namespace   http://sorah.jp/
// @description avoid cussion
// @include     http://b.hatena.ne.jp/entry/*
// ==/UserScript==

var i = null
i = setInterval(function() {
  if(document.getElementById("highlighted-bookmark")) {
    clearInterval(i);
    location.href = document.getElementById("head-entry-link");
  }
}, 500);
