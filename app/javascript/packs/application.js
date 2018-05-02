/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import blogSlider from './blog_slider';
import initHomeSlider from './home_slider';

document.addEventListener('turbolinks:load', function() {
  blogSlider();
  initHomeSlider();
});

document.addEventListener('turbolinks:before-cache', function() {
  $("#rev_slider_one ul").trigger('destroy.owl.carousel').find('.owl-stage-outer').children().unwrap();;
  $(".blog-carousel").trigger('destroy.owl.carousel').find('.owl-stage-outer').children().unwrap();;
});
