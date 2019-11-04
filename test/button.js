var b = new TjsButton("Test")
    .setBgColor(255, 0, 0)
    .bind(function () {
      tjs_print("Test");
    });

/* Attach */
tjs_attach(b);