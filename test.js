/* Old API */
/*var button1 = duk_create_button("Button1");

duk_bind_button(button1, function (idx) {
    duk_print("Button " + idx);
});

var button2 = duk_create_button("Button2");

duk_bind_button(button2, function (idx) {
    duk_print("Button " + idx);
}); */

/* New API */
var b1 = new TjsButton("Button1")
    .bind(function () {
        this.print();
    })
    .click();

var b2 = new TjsButton("Button2")
    .bind(function () {
        this.print();
    })
    .click();