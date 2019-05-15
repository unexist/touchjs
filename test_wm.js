/* WM */
var wm = new TjsWM();
var wins = wm.getWindows();

wins.forEach(function (win) {
    tjs_print(
        "win: title=" + win.getTitle() +
        ", pid=" + win.getPid() +
        ", rect=" + win.getRect());

    if (win.isMovable())
        win.setXY(10, 10);

    if (win.isResizable())
        win.setWH(100, 100);
});