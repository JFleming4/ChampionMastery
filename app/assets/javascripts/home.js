$(document).ready(function() {
  $( "#ChampionSort, #chestFilter").change(function() {
    var sortingType = $("#ChampionSort").val();
    var filter = $("#chestFilter").val();
    championsElement = $("#champions");
    championsElement.fadeTo( "slow", 0.33 );
    $.ajax({
      type:'get',
      url:window.location.href+'/build_grid_view',
      data:{
        sort:sortingType,
        filter_type: filter,
      },
    }).done(function(result){
      champs="";
      result.data.forEach(function(arr){
        champs+='<div class="row championRow">';
        console.log(champs);
        arr.forEach(function(champion){
          champs+='<div class="col-xs-2 champion">';
          champs+='<img class="img-responsive" title="Champion Level: '+champion.lvl+'&#013;Next Level:'+champion.nxLvl+'" src="'+champion.img+'">';
          champs+= champion.name;
          champs+="</div>";
          console.log(champion.img);
        });
        champs+="</div>";
      });
      championsElement.empty();
      championsElement.append(champs);
      championsElement.fadeTo("slow",1);
    });
  });
});
