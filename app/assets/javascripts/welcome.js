$(document).ready(function() {

  $("form").submit(function(e){
    var summonerName = $('#person_sumName').val();
    var summonerRegion = $('#person_region').val();

    e.preventDefault();
    window.location.replace("http://localhost:3000/"+summonerRegion+"/"+summonerName);
  });
});
