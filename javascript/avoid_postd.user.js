// ==UserScript==
// @name        avoid_postd
// @namespace   http://sorah.jp/
// @description redirect to original article
// @include     http://postd.cc/*
// ==/UserScript==

var original = document.querySelector('.post-meta .block-text-original-text a')
if ( original ) {
  location.href = original.href;
}
