var rgb = [0, 0, 0];
var idx = 0;

var l1 = new TjsLabel("TouchJS");

var b1 = new TjsButton("Red")
    .setBgColor(255, 0, 0)
    .bind(function () {
        idx = 0;
        s1.setPercent(rgb[idx] * 100 / 255).setBgColor(255, 0, 0);
        l1.setFgColor.apply(l1, rgb);
    });

var b2 = new TjsButton("Green")
    .setBgColor(0, 255, 0)
    .bind(function () {
        idx = 1;
        s1.setPercent(rgb[idx] * 100 / 255).setBgColor(0, 255, 0);
        l1.setFgColor.apply(l1, rgb);
    });

var b3 = new TjsButton("Blue")
    .setBgColor(0, 0, 255)
    .bind(function () {
        idx = 2;
        s1.setPercent(rgb[idx] * 100 / 255).setBgColor(0, 0, 255);
        l1.setFgColor.apply(l1, rgb);
    });

var s1 = new TjsSlider(0)
    .bind(function (self, value) {
        tjs_print(value);
        tjs_print(self.getPercent());

        rgb[idx] = parseInt(255 * self.getPercent() / 100);

        l1.setFgColor.apply(l1, rgb);
    });

var c1 = new TjsCommand("ls -l src/");

tjs_print(c1.exec().getOutput());

/* Attach */
tjs_attach(l1);
tjs_attach(b1);
tjs_attach(b2);
tjs_attach(b3);
tjs_attach(s1);

/* Dump */
tjs_print(l1);
tjs_print(b1);
tjs_print(b2);
tjs_print(b3);
tjs_print(s1);