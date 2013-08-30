(function() {
  var requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame ||
                              window.webkitRequestAnimationFrame || window.msRequestAnimationFrame;
  window.requestAnimationFrame = requestAnimationFrame;
})();
var stop, stopp, resize = 1, lt = 0, first = false;
function setup(){
    $(".canv").css("opacity", "1")
    $(".canv").css("z-index", "10")
    $("#ide").css("opacity", "0.5")
    stopp = false;
    muu.cleanAll();
    var roo1 = muu.addCanvas("canvas1", false);
    var roo2 = muu.addCanvas("canvas2", true);
    muu.addAtlas("img/atlas2.png", "img/atlas2.js")
    stop = function(){
        stopp = true;
        $(".canv").css("opacity", "0.5")
        $(".canv").css("z-index", "0")
        $("#ide").css("opacity", "1")

    }

    var mask = {roo1:roo1, roo2:roo2, Circle: Circle};

    function render(t){if(!stopp){
        if(first){ lt = t; first = false}
        mask.render(t-lt);
        muu.render();
        requestAnimationFrame(render);
    }}

    muu.whenReady(function(){
        (new Function("with(this){"+CoffeeScript.compile(editor.getValue(), {bare: true})+"}")).call(mask);
        first = true;
        requestAnimationFrame(render);
    });
}

var coding = true;
function run(){
    if (coding) setup();
    else stop();
    coding = !coding;
    $("#run").toggleClass("btn-success")
    $("#run").toggleClass("btn-warning")
    $("#run-icon").toggleClass("icon-play-circle")
    $("#run-icon").toggleClass("icon-pause")
    if(coding)
        $(".canv").css("pointer-events", "none");
    else $(".canv").css("pointer-events", "auto")
}


