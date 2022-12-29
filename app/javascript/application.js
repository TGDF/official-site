import { Turbo } from "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import Carousel from 'stimulus-carousel'
import 'swiper/css/bundle'

import NavbarController from "./controllers/navbar_controller"

window.Stimulus = Application.start()

Stimulus.register('navbar', NavbarController)
Stimulus.register('carousel', Carousel)

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
