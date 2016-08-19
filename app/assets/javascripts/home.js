$(document).ready(function() {
  $( "#ChampionSort, #chestFilter").change(function() {
    var sortingType = $("#ChampionSort").val();
    var filter = $("#chestFilter").val();
    $.ajax({
      type:'get',
      url:window.location.href+'/build_grid_view',
      data:{
        sort:sortingType,
        filter_type: filter,
      },
    }).done(function(result){
      championsElement = $("#champions");
      champs="";
      result.data.forEach(function(arr){
        champs+='<div class="row championRow">';
        console.log(champs);
        arr.forEach(function(champion){
          champs+='<div class="col-xs-2 champion">';
          champs+='<img class="img-responsive" src="'+champion.img+'">';
          champs+= champion.name;
          champs+="</div>";
          console.log(champion.img);
        });
        champs+="</div>";
      });
      championsElement.fadeOut(500, function(){
        championsElement.empty();
        championsElement.append(champs);
      });
      championsElement.fadeIn(500);
    });
  });
});
