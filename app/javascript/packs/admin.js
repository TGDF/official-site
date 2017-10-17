/**
 * Admin Portal
 */


const initAdminLTE = () => {
  $('body').layout().data('lte.layout').activate();
  $('[data-widget="tree"]').tree();
}

document.addEventListener('turbolinks:load', () => {
  initAdminLTE();
});
