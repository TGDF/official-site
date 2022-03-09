/**
 * Admin Portal
 */

require("@rails/ujs").start();
require("turbolinks").start();

// Core UI
require.context("@coreui/icons/sprites", true, /\.svg$/);
import "@coreui/coreui/scss/coreui";
import { Sidebar } from "@coreui/coreui";

// CKEditor
import "@ckeditor/ckeditor5-build-classic/build/ckeditor";

const editors = [];

const setupCKEditors = () => {
  document.querySelectorAll("[data-editor=true]").forEach($el => {
    $el.required = false;
    ClassicEditor.create($el, {
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

document.addEventListener("turbolinks:load", () => {
  setupCKEditors();
  Array.from(document.querySelectorAll(".c-sidebar")).forEach(element => {
    Sidebar._sidebarInterface(element);
  });
});

document.addEventListener("turbolinks:before-cache", () => {
  // destroyCKEditors();
  Array.from(document.querySelectorAll(".c-sidebar")).forEach(element => {
    Sidebar._sidebarInterface(element);
  });
});
