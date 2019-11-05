/* WM */
var wm = new TjsWM();

tjs_print("wm: trusted=" + wm.isTrusted());

/* Events */
wm.observe("win_open", function (win) {
    tjs_print("Open: name=" + win.getTitle() + ", id=" + win.getId() + ", frame=" + win.getFrame());
});

wm.observe("win_move", function (win) {
    tjs_print("Move: name=" + win.getTitle() + ", id=" + win.getId() + ", frame=" + win.getFrame());
});

wm.observe("win_focus", function (win) {
    tjs_print("Focus: name=" + win.getTitle() + ", id=" + win.getId() + ", frame=" + win.getFrame());
});

wm.observe("win_title", function (win) {
    tjs_print("Title: name=" + win.getTitle() + ", id=" + win.getId() + ", frame=" + win.getFrame());
});

wm.observe("win_close", function (win) {
    tjs_print("Close: name=" + win.getTitle() + ", id=" + win.getId() + ", frame=" + win.getFrame());
});

wm.observe("win_resize", function (win) {
    tjs_print("Resize: name=" + win.getTitle() + ", id=" + win.getId() + ", frame=" + win.getFrame());
});