/* WM */
var wm = new TjsWM();

tjs_print("wm: trusted=" + wm.isTrusted());

/* Screens */
var screens = wm.getScreens();

tjs_print(screens);

screens.forEach(function (screen) {
    tjs_print("screen: frame=" + screen.getFrame());
});

/* Windows */
var wins = wm.getWindows();

wins.filter(function (win) {
    return win.isNormalWindow();
}).forEach(function (win) {
    tjs_print("win: id=" + win.getId() +
        ", title=" + win.getTitle() +
        ", role=" + win.getRole() +
        ", subrole=" + win.getSubrole() +
        ", frame=" + win.getFrame() +
        ", pid=" + win.getPid() +
        ", movable=" + win.isMovable() +
        ", resizable=" + win.isResizable() +
        ", minimized=" + win.isMinimized() +
        ", hidden=" + win.isHidden() +
        ", normal=" + win.isNormalWindow() +
        ", sheet=" + win.isSheet()
    );

    /*if (win.isMovable())
        win.setXY(10, 10);

    if (win.isResizable())
        win.setWH(100, 100);*/
});

/* Events */
wm.observe("win_move", function (win) {
    tjs_print("Move: id=" + win.getId() + ", frame=" + win.getFrame());
});