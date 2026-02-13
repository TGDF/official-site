/**
 * Admin Portal
 */
import { Turbo } from "@hotwired/turbo-rails"

// Stimulus
import { Application } from "@hotwired/stimulus"
import SidebarController from "../assets/javascripts/controllers/sidebar_controller"
import FlashMessageController from "../assets/javascripts/controllers/flash_message_controller"
import DropdownController from "../assets/javascripts/controllers/dropdown_controller"

// Initialize Stimulus
const application = Application.start()
application.register("sidebar", SidebarController)
application.register("flash-message", FlashMessageController)
application.register("dropdown", DropdownController)

// CKEditor
import {
  ClassicEditor,
  Essentials,
  Bold,
  Italic,
  Heading,
  Link,
  List,
  Paragraph,
  BlockQuote,
  Image,
  ImageUpload,
  ImageInsert,
  Table,
  TableToolbar,
  MediaEmbed,
  Autoformat,
  PasteFromOffice,
  SimpleUploadAdapter
} from 'ckeditor5';
import 'ckeditor5/ckeditor5.css';
import '../assets/stylesheets/ckeditor-tailwind-fix.css';

const editors = [];

const setupCKEditors = () => {
  document.querySelectorAll("[data-editor=true]").forEach($el => {
    $el.required = false;
    ClassicEditor.create($el, {
      licenseKey: 'GPL',
      plugins: [
        Essentials,
        Bold,
        Italic,
        Heading,
        Link,
        List,
        Paragraph,
        BlockQuote,
        Image,
        ImageUpload,
        ImageInsert,
        Table,
        TableToolbar,
        MediaEmbed,
        Autoformat,
        PasteFromOffice,
        SimpleUploadAdapter
      ],
      toolbar: [
        'heading',
        '|',
        'bold',
        'italic',
        'link',
        'bulletedList',
        'numberedList',
        '|',
        'insertImage',
        'blockQuote',
        'insertTable',
        'mediaEmbed',
        '|',
        'undo',
        'redo'
      ],
      simpleUpload: {
        uploadUrl: "/admin/images"
      },
      table: {
        contentToolbar: ['tableColumn', 'tableRow', 'mergeTableCells']
      }
    }).then(editor => editors.push(editor));
  });
};

const destroyCKEditors = () => {
  editors.forEach(editor => editor.destroy());
};

document.addEventListener("turbo:load", () => {
  setupCKEditors();
});
