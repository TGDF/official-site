/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// JotForm
window.handleIFrameMessage = function(e) {
    if (typeof e.data === 'object') {
        return;
    }
    var args = e.data.split(":");
    let iframe = null;
    if (args.length > 2) {
        iframe = document.getElementById("JotFormIFrame");
    }
    if (!iframe) {
        return;
    }
    switch (args[0]) {
        case "scrollIntoView":
            iframe.scrollIntoView();
            break;
        case "setHeight":
            iframe.style.height = args[1] + "px";
            break;
        case "collapseErrorPage":
            if (iframe.clientHeight > window.innerHeight) {
                iframe.style.height = window.innerHeight + "px";
            }
            break;
        case "reloadPage":
            window.location.reload();
            break;
        case "loadScript":
            var src = args[1];
            if (args.length > 3) {
                src = args[1] + ':' + args[2];
            }
            var script = document.createElement('script');
            script.src = src;
            script.type = 'text/javascript';
            document.body.appendChild(script);
            break;
        case "exitFullscreen":
            if (window.document.exitFullscreen) window.document.exitFullscreen();
            else if (window.document.mozCancelFullScreen) window.document.mozCancelFullScreen();
            else if (window.document.mozCancelFullscreen) window.document.mozCancelFullScreen();
            else if (window.document.webkitExitFullscreen) window.document.webkitExitFullscreen();
            else if (window.document.msExitFullscreen) window.document.msExitFullscreen();
            break;
    }
    var isJotForm = (e.origin.indexOf("jotform") > -1) ? true : false;
    if (isJotForm && "contentWindow" in iframe && "postMessage" in iframe.contentWindow) {
        var urls = {
            "docurl": encodeURIComponent(document.URL),
            "referrer": encodeURIComponent(document.referrer)
        };
        iframe.contentWindow.postMessage(JSON.stringify({
            "type": "urls",
            "value": urls
        }), "*");
    }
};
if (window.addEventListener) {
    window.addEventListener("message", handleIFrameMessage, false);
} else if (window.attachEvent) {
    window.attachEvent("onmessage", handleIFrameMessage);
}

window.addEventListener('turbolinks:load', function() {
  $('.carousel').carousel()
});
