// some empty variables to force declaration
last_change = "-";
testdata_status = "-";
setup_status = "-";
qc_status = "-";
load_avg = "-";
ascat = {};
pindel = {};
caveman = {};
brass = {};


function reload_js(src) {
    $('script[src="' + src + '"]').remove();
    $('<script>').attr('src', src).appendTo('head');
}


$(document).ready(function () {
(function countdown(remaining) {
    if(remaining <= 0)
        location.reload(true);
    document.getElementById('countdown').innerHTML = remaining;
    document.getElementById('last_mod').innerHTML = last_change;
    document.getElementById('testdata_status').innerHTML = testdata_status;
    document.getElementById('setup_status').innerHTML = setup_status;
    document.getElementById('qc_status').innerHTML = qc_status;
    document.getElementById('total_cpus').innerHTML = total_cpus;
    document.getElementById('mt_name').innerHTML = mt_name;
    document.getElementById('wt_name').innerHTML = wt_name;
    document.getElementById('started_at').innerHTML = started_at;
    document.getElementById('completed_at').innerHTML = completed_at;
    //document.getElementById('scriptmod').innerHTML = scriptmod;

    setTimeout(function(){ countdown(remaining - 1); }, 1000);
})(30); // 5 seconds

reload_js('../data/progress.js');

// chart stuff
var ctx = document.getElementById("ascat");
var myBarChart = new Chart(ctx, ascat);
var ctx2 = document.getElementById("pindel");
var myBarChart2 = new Chart(ctx2, pindel);
var ctx3 = document.getElementById("caveman");
var myBarChart3 = new Chart(ctx3, caveman);
var ctx4 = document.getElementById("brass");
var myBarChart4 = new Chart(ctx4, brass);
var ctx5 = document.getElementById("load_trend");
var myBarChart4 = new Chart(ctx5, load_trend);
});
