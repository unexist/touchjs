/* WM */
var wm = new TjsWM();
var wins = wm.getWindows();

wins.forEach(function (win) {
    tjs_print(
        "win: title=" + win.getTitle() +
        ", pid=" + win.getPid() +
        ", rect=" + win.getRect() +
        ", movable=" + win.isMovable() +
        ", resizable=" + win.isResizable() +
        ", minimized=" + win.isMinimized() +
        ", hidden=" + win.isHidden());

    if (win.isMovable())
        win.setXY(10, 10);

    if (win.isResizable())
        win.setWH(100, 100);
});