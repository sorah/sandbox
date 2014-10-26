// ==UserScript==
// @name pixiv-unmedium
// @namespace sorah.jp
// @match https://www.pixiv.net/member_illust.php
// @match http://www.pixiv.net/member_illust.php
// @match https://www.pixiv.net/member_illust.php?*
// @match http://www.pixiv.net/member_illust.php?*
// @run-at document-end
// ==/UserScript==

var link = document.querySelector(".works_display a");
if (link && !link.href.match(/mode=manga/)) {
  var img = document.querySelector(".works_display img");

  var unmedium = function () {
    img.setAttribute('height', img.height);
    img.setAttribute('width', img.width);
    img.onload = null;
    if (img.src.match(/img-master/)) {
      img.src = "http://i3.pixiv.net/img-original/img/" + img.src.match(/\/img\/(.+)$/)[1];
      img.src = img.src.replace(/_master\d+/, '');
    } else {
      img.src = img.src.replace(/_m/, '');
    }
    document.querySelector(".works_display").innerHTML += "<p>" + img.src + "</p>";
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

    img.src = img.attributes['data-src'].value.replace(/_p/, '_big_p');
    container.innerHTML += "<p>" + img.src + "</p>";
  }
}
