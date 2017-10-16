/**
 * Admin Portal
 */

let $layout;

document.addEventListener('turbolinks:load', () => {
  if (!$layout) {
    $layout = $('body').layout().data('lte.layout');
  }

  $layout.activate();
});
