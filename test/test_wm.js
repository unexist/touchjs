/* WM */
var wm = new TjsWM();

/* Screens */
var screens = wm.getScreens();

screens.forEach(function (screen) {
    tjs_print("screen: frame=" + screen.getFrame());
});

/* Windows */
var wins = wm.getWindows();

wins.forEach(function (win) {
    tjs_print("win: title=" + win.getTitle() +
        ", role=" + win.getRole() +
        ", subrole=" + win.getSubrole() +
        ", frame=" + win.getFrame() +
        ", pid=" + win.getPid() +
        ", movable=" + win.isMovable() +
        ", resizable=" + win.isResizable() +
        ", minimized=" + win.isMinimized() +
        ", hidden=" + win.isHidden()
    );

    /*if (win.isMovable())
        win.setXY(10, 10);

    if (win.isResizable())
        win.setWH(100, 100);*/
});