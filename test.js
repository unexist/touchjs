/* Create buttons */
var button1 = duk_create_button("Button1");

duk_bind_button(button1, function () {
    duk_print("Button 1");
});

var button2 = duk_create_button("Button2");

duk_bind_button(button2, function () {
    duk_print("Button 2");
});

/*setTimeout(_ => {
    duk_remove_button(button);
}, 50000);*/