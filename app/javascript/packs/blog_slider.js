export default function() {
  const $el = $('.blog-carousel');
  if($el.length) {
    $('.blog-carousel').owlCarousel({
      loop:true,
      margin:30,
      nav:true,
      dots: false,
      autoplayHoverPause:false,
      autoplay: 6000,
      smartSpeed: 700,
      navText: [ '<span class="fa fa-angle-left"></span>', '<span class="fa fa-angle-right"></span>' ],
      responsive:{
        0:{
          items:1
        },
        600:{
          items:1
        },
        800:{
          items:1
        },
        1024:{
          items:1
        },
        1100:{
          items:1
        },
        1200:{
          items:1
        }
      }
    })
  }
}
