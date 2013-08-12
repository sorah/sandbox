// ==UserScript==
// @name pixiv-unmedium
// @namespace sorah.jp
// @match http://www.pixiv.net/member_illust.php?mode=medium&illust_id=*
// @match https://www.pixiv.net/member_illust.php?mode=medium&illust_id=*
// @run-at document-end
// ==/UserScript==

var img = document.querySelector(".works_display img");

var unmedium = function () {
  img.setAttribute('height', img.height);
  img.setAttribute('width', img.width);
  img.src = img.src.replace(/_m/, '');
};

if (img.complete) {
  unmedium();
} else {
  img.onload = unmedium;
}

document.querySelector(".works_display").innerHTML += "<p>" + img.src + "</p>";
