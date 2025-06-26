/**
 * Admin Portal
 */
import { Turbo } from "@hotwired/turbo-rails"

// Stimulus
import { Application } from "@hotwired/stimulus"
import SidebarController from "../assets/javascripts/controllers/sidebar_controller"
import FlashMessageController from "../assets/javascripts/controllers/flash_message_controller"

// Core UI
import "@coreui/coreui/dist/css/coreui.min.css"
import { Sidebar } from "@coreui/coreui"

// Initialize Stimulus
const application = Application.start()
application.register("sidebar", SidebarController)
application.register("flash-message", FlashMessageController)

// CKEditor
import ClassicEditor from "@ckeditor/ckeditor5-build-classic/build/ckeditor"

const editors = [];

const setupCKEditors = () => {
  document.querySelectorAll("[data-editor=true]").forEach($el => {
    $el.required = false;
    ClassicEditor.create($el, {
      licenseKey: 'GPL',
      ckfinder: {
        // Upload the images to the server using the CKFinder QuickUpload command.
        uploadUrl: "/admin/images"
      }
    }).then(editor => editors.push(editor));
  });
};

const destroyCKEditors = () => {
  editors.forEach(editor => editor.destroy());
};

document.addEventListener("turbo:load", () => {
  setupCKEditors();
  Array.from(document.querySelectorAll(".c-sidebar")).forEach(element => {
    Sidebar._sidebarInterface(element);
  });
});

document.addEventListener("turbo:before-cache", () => {
  // destroyCKEditors();
  Array.from(document.querySelectorAll(".c-sidebar")).forEach(element => {
    Sidebar._sidebarInterface(element);
  });
});
