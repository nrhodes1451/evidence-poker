// GA Tracking Code Snippet

//(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
//(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
//m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
//})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

// ga('create', 'UA-97473176-1', 'auto');
// ga('send', 'pageview');

// End GA Tracking Code Snippet

$(document).ready(function(){
  $('#deck').click(function(){
    $('#btn_deal').click();
  });

	// Loading bars
	$('.plotlybars-bar').each(function(){
    $(this).toggleClass('plotlybars-bar');
    delay = Math.random()*2;
    $(this).css( "-webkit-animation-delay", -delay+"s" );
    $(this).toggleClass('plotlybars-bar');
  });

  // Change diagnostics download icons
  $(".icon-diagnostics i").each(function(){
    $(this).toggleClass('fa-download');
    $(this).toggleClass('fa-wrench');
  });
  // Change line-chart download icons
  $(".icon-line-chart i").each(function(){
    $(this).toggleClass('fa-download');
    $(this).toggleClass('fa-line-chart');
  });

	// Keydown events

	$("body").keydown(function(e){
    if(e.which == 27){
      // Escape
      $('.error-notification-overlay').hide();
      $('.shiny-notification-error').hide();
    }
  });

  // Download GA Event Tracking
	$(".shiny-download-link").on('click', function(){
	  action = this.parentNode.parentNode.children[0].textContent.trim();
	  label = $(this).text().trim();
	  ga('send', 'event', 'Download', action, label);
	});
});

// Loading messages
var shiny_busy = 0;
setInterval(function(){
  shiny_busy = Math.max(shiny_busy-1,0);
  if(!$('html').hasClass('shiny-busy') &&
    shiny_busy===0) $("#loading").hide();
}, 10);

check_shiny_busy = function(){
  if(shiny_busy>0) return(true);

  if($('html').hasClass('shiny-busy')){
    shuffle_loading_messages();
    shiny_busy=20;
    return(true);
  }
  return(false);
}

var loading_messages = [
  'Reticulating Splines',
  'Cogitating',
  'Inverting Orthogonal Matrices',
  'Identifying Systemic Anomalies',
  'Verifying P = NP',
  'Extrapolating Asymptotes',
  'Constraining Coefficients<br>&isin; &#8477;<sup>n</sup>',
  'Minimising Loss Function',
  'Enabling SQL Injection',
  'Caclculating Complex Conjugates',
  'Parsing Pseudoparameters',
  'Floating Teraflops',
  'Aligning Covariance Matrices',
  'Decomposing Singular Values',
  'Inserting Sublimated Messages',
  'Integrating Cross-Vectors',
  'Iterating Cellular Automata',
  'Seeding Regression Integration Parameters',
  'Tessellating Transistors',
  'Backpropagating Neural Pathways'
];
shuffle_loading_messages = function(){
  $('.plotlybars-text').html(
    loading_messages[Math.floor(Math.random()*loading_messages.length)]+
    '...'
  );
}