// ==UserScript==
// @name pixiv-unmedium
// @namespace sorah.jp
// @match https://www.pixiv.net/member_illust.php
// @match http://www.pixiv.net/member_illust.php
// @match https://www.pixiv.net/member_illust.php?*
// @match http://www.pixiv.net/member_illust.php?*
// @run-at document-end
// ==/UserScript==

var unmedium = function (src) {
  if (src.match(/img-master/)) {
    var m = src.match(/http:\/\/(.+?)\.pixiv.net/);
    var host = "i3.pixiv.net";
    if (m) host = m[1] + ".pixiv.net";

    src = "http://" + host + "/img-original/img/" + src.match(/\/img\/(.+)$/)[1];
    src = src.replace(/_master\d+/, '');
  } else {
    src = src.replace(/_m/, '');
  }
  return src;
}

var link = document.querySelector(".works_display a");
if (link && !link.href.match(/mode=manga/)) {
  var img = document.querySelector(".works_display img");

  var unmedium = function () {
    img.setAttribute('height', img.height);
    img.setAttribute('width', img.width);
    img.onload = null;
    var originalSrc = img.src;
    src = unmedium(src);
    document.querySelector(".works_display").innerHTML += "<p>" + originalSrc + "<br>" + img.src + "</p>";
  };

  if (img.complete) {
    unmedium();
  } else {
    img.onload = unmedium;
  }
}

if (location.search.match(/mode=manga/)) {
  var containers = document.querySelectorAll('.manga .item-container');

  for (var i = 0; i < containers.length; i++) {
    var container = containers[i];
    var img = container.querySelector('img');

    img.src = unmedium(img.attributes['data-src'].value);
    container.innerHTML += "<p>" + img.src + "</p>";
  }
}
