/* WM */
var wm = new TjsWM();

tjs_print("wm: trusted=" + wm.isTrusted());

/* Events */
wm.observe("win_move", function (win) {
    tjs_print("Move: name=" + win.getTitle() + ", id=" + win.getId() + ", frame=" + win.getFrame());
});