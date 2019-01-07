/* Create buttons */
var button1 = duk_create_button("Button1");

duk_bind_button(button1, function (idx) {
    duk_print("Button " + idx);
});

var button2 = duk_create_button("Button2");

duk_bind_button(button2, function (idx) {
    duk_print("Button " + idx);
});

/*setTimeout(_ => {
    duk_remove_button(button);
}, 50000);*/