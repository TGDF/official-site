/**
 * Admin Portal
 */

const initAdminLTE = () => {
  $('body').layout().data('lte.layout').activate();
  $('[data-widget="tree"]').tree();
}

const editors = [];

const setupCKEditors = () => {
  document.querySelectorAll('[data-editor=true]').forEach($el => {
    ClassicEditor.create($el).then(editor => editors.push(editor));
  });
}

const destroyCKEditors = () => {
  editors.forEach(editor => editor.destroy());
}

document.addEventListener('turbolinks:load', () => {
  initAdminLTE();
  setupCKEditors();
});

document.addEventListener('turbolinks:before-cache', () => {
  destroyCKEditors();
});
