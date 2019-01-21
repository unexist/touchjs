var l1 = new TjsLabel("Foobar");

var b1 = new TjsButton("Red")
    .setBgColor(255, 0, 0)
    .bind(function () {
        this.print();
        l1.setFgColor(255, 0, 0);
    });

var b2 = new TjsButton("Blue")
    .setBgColor(0, 0, 255)
    .bind(function () {
        this.print();
        l1.setFgColor.apply(l1, tjs_rgb("#0000ff"));
    });

var b3 = new TjsButton("Green")
    .setBgColor(0, 255, 0)
    .bind(function () {
        tjs_quit();
    });


/* Dump */
tjs_print(l1);
tjs_print(b1);
tjs_print(b2);
tjs_print(b3);