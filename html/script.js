var CreatorActive = false;
var RaceActive = false;

$(document).ready(function(){
    window.addEventListener('message', function(event){
        var data = event.data;
        if (data.action == "Update") {
            UpdateUI(data.type, data);
        } else if (data.action == "Countdown") {
            UpdateCountdown(data)
        } else if (data.action == "Finish") {
            UpdateCountdown(data)
        }
    });
});

function secondsTimeSpanToHMS(s) {
    var m = Math.floor(s/60); //Get remaining minutes
    s -= m*60;
    return (m < 10 ? '0'+m : m)+":"+(s < 10 ? '0'+s : s); //zero padding on minutes and seconds
}

function UpdateCountdown(data) {
    if(typeof data.data.value == 'number') {
        $("#countdown-number").show();
        $("#countdown-number").html(data.data.value);
        $("#countdown-number").fadeOut(900);
    } else {
        $("#countdown-text").show();
        $("#countdown-text").html(data.data.value);
        $("#countdown-text").fadeOut(4000);
    }
}

function UpdateUI(type, data) {
    if (type == "race") {
        if (data.active) {
            if (!RaceActive) {
                RaceActive = true;
                $(".race").fadeIn(300);
            }
            if (data.data.Type === 'outrun') {
                if (data.data.Role === 'mouse') {
                    $("#race-position").html('🐭');
                } else {
                    $("#race-position").html('🐱');
                }
                $(".outrun-timer").show()
                $("#outrun-time").html(data.data.OutrunTimer + ' / ' + data.data.OutrunTimeToWin);
                if(data.data.Distance === 0 && data.data.Role === 'mouse') {
                    $("#outrun-distance").html('WINNING');
                } else if (data.data.Distance === 0 && data.data.Role === 'cat') {
                    $("#outrun-distance").html('LOSING');
                } else {
                    $("#outrun-distance").html(Math.round(data.data.Distance));
                }
            } else {
                $("#race-position").html(data.data.Position + ' / ' + 2);
            }
            if(data.data.Started) {
                $("#race-time").html(secondsTimeSpanToHMS(data.data.Time));
            }
            if (data.data.Ghosted) {
                $("#race-ghosted-value").html('👻');
                $("#race-ghosted-span").show();
        
            } else {
                $("#race-ghosted-value").html('');
                $("#race-ghosted-span").hide();
            }
        } else {
            RaceActive = false;
            $(".outrun-timer").fadeOut(200)
            $(".race").fadeOut(300);
        }
    }
}