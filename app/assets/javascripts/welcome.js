$(document).ready(function() {

  $("form").submit(function(e){
    var summonerName = $('#person_sumName').val();
    var summonerRegion = $('#person_region').val();

    e.preventDefault();
    // Local path
    // window.location.replace("http://localhost:3000/"+summonerRegion+"/"+summonerName);

    // Deploy Path
    window.location.replace("https://champion-mastery.herokuapp.com/"+summonerRegion+"/"+summonerName);
  });
});
