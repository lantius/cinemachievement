function generateRow(json){
    if($.inArray(json['title'], seen_films) > -1){
      json['starset'] = 'set'; 
    } else {
      json['starset'] = 'unset'; 
    }
    json['counttemp'] = [];
    for(var i = 0 ; i < json['oscars']; i++){
        json['counttemp'].push('<img class="oscar" src="oscar.jpg">')
    }
    json['countimgs'] = json['counttemp'].join("\n");
    
    var img = '<img class="star ${starset}" src="staricon.png" title="I\'ve seen ${title}!">';
    var markup = "<tr><td>" + img + "</td><td class='movietitle'>${title}</td><td class='count' data-count=${oscars} data-title='${title}'>{{html countimgs}}</td></tr>";
    $.template( "movieTemplate", markup);
    return $.tmpl("movieTemplate", json);
}

function generateTable(){
    //assume sorted order
    var len = movies_data['movies'].length;
    rows = [];
    for(var i = 0; i < len; i++){
        row = generateRow(movies_data['movies'][i]);
        // This is slow. We should add them all at once
        $('#maintable').append(row);
    }
}

function generateOscars(){
    var len = movies_data['movies'].length;
    var total = 0;
    var numSeen = 0;
    var oscars = [];
    for(var i = 0; i < len; i++){
        total += movies_data['movies'][i]['oscars'];
        if($.inArray(movies_data['movies'][i]['title'], seen_films) > -1){
            numSeen += movies_data['movies'][i]['oscars'];
        }
    }
    for(i = 0; i < total; i++){
        oscars.push('<img class="oscar unset" src="oscar-sm.jpg">');
    }
    var content = oscars.join("\n");
    $('#oscars').html(content);
    setOscars(numSeen);
}

$(function() {
  generateTable();
  generateOscars();
  
  $("#maintable").on('mouseenter', ".star", function(){
      $(this).addClass('hover');
  });
  $("#maintable").on('mouseleave', ".star", function(){
      $(this).removeClass('hover');
  });

  $("#maintable").on('click', ".star", function(){
      $(this).removeClass('hover');
      $(this).toggleClass('unset set');
      if(hidewatch){
          $("tr:has(.set)").hide('slow');
      }
      var total = 0;
      var films = [];
      $("tr:has(.set) .count").each(function(){
          total += Number($(this).data('count'));
          films.push($(this).data('title'))
      });
      setOscars(total);
      $.ajax({
        type: "POST",
        url: "/seenfilms",
        data: {'films' : films },
      });

  });

  $("#hidewatch").on('click', function(){
      $("tr:has(.set)").toggle('slow');
      $(this).toggle();
      $('#showwatch').toggle();
      hidewatch = true;
  });

  $("#showwatch").on('click', function(){
      $("tr:has(.set)").toggle('slow');
      $(this).toggle();
      $('#hidewatch').toggle();
      hidewatch = false;
  });
});

var hidewatch = false;
// $(".unsetstar").bind('click', function(){
//     $(this).class('opacity', 1.0)
// });

function setOscars(count) {
    var set = 0;
    $('#oscars .oscar').each(function(){
        if(set++ < count){
            $(this).removeClass('unset');
            $(this).addClass('set');
        } else {
            $(this).addClass('unset');
            $(this).removeClass('set');
        }
    });
    
    $('#oscarcount').text(count +'/' + set)
}
