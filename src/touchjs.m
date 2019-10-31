/**
 * @package TouchJS
 *
 * @file Main functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import <Cocoa/Cocoa.h>

#include <unistd.h>

#include "touchjs.h"
#include "delegate.h"
#include "embed.h"

#include "common/callback.h"

/******************************
 *           Helper           *
 ******************************/

 /**
  * Print usage info
  **/

 static void tjs_usage(void) {
    NSLog(@"Usage: %s [OPTIONS]\n\n" \
           "Options:\n" \
           "  -f FILE           Eval file \n" \
           "  -h                Show this help and exit\n" \
           "  -v                Show version info and exit\n" \
           "  -l LEVEL[,LEVEL]  Set logging levels:\n" \
           "                      info     => General information (default)\n" \
           "                      duk      => Duktape logging\n" \
           "                      observer => AX events\n" \
           "                      debug    => All debugging messages (noisy!)\n" \
           "                      error    => Log only errors (default)\n" \
           "  -q                No logging output\n" \
           "  -d                Print all debugging messages\n\n" \
           "\nPlease report bugs at %s\n",
        PKG_NAME, PKG_BUGREPORT);
}

/**
 * Print version info
 **/

static void tjs_version(void) {
  NSLog(@"%s v%s - Copyright (c) 2019 Christoph Kappel\n" \
         "Released under the GNU General Public License\n",
        PKG_NAME, PKG_VERSION);
}

/**
 * Log handler
 *
 * @param[in]  level  Log level
 * @param[in]  func   Name of the calling function
 * @param[in]  line   Line number of the call
 * @param[in]  fmt    Message format
 * @param[in]  ...    Variadic arguments
 **/

void tjs_log(int level, const char *func, int line, const char *fmt, ...) {
    va_list ap;
    char buf[255];
    int guard;

    /* Check loglevel */
    if(0 == (touch.loglevel & level)) return;

    /* Get variadic arguments */
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    switch (level) {
        case TJS_LOGLEVEL_INFO:
            NSLog(@"[INFO] %s", buf);
            break;
        case TJS_LOGLEVEL_DUK:
            NSLog(@"[DUK %s:%d] %s", func, line, buf);
            break;
        case TJS_LOGLEVEL_OBSERVER:
            NSLog(@"[OBSERVER %s:%d] %s", func, line, buf);
            break;
        case TJS_LOGLEVEL_DEBUG:
            NSLog(@"[DEBUG %s:%d] %s", func, line, buf);
            break;
        case TJS_LOGLEVEL_ERROR:
            NSLog(@"[ERROR %s:%d] %s", func, line, buf);
            break;
    }
}

/**
 * Parse loglevel string
 *
 * @param[in]  str  Loglevel string
 *
 * @return Parsed loglevel
 **/

static int tjs_level(const char *str) {
    int level = 0;
    char *tokens = NULL, *tok = NULL;

    tokens = strdup(str);
    tok    = strtok((char *)tokens, ",");

    /* Parse levels */
    while (tok) {
        if (0 == strncasecmp(tok, "info", 4)) {
            level |= TJS_LOGLEVEL_INFO;
        } else if (0 == strncasecmp(tok, "duk", 3)) {
            level |= TJS_LOGLEVEL_DUK;
        } else if (0 == strncasecmp(tok, "observer", 8)) {
            level |= TJS_LOGLEVEL_OBSERVER;
        } else if (0 == strncasecmp(tok, "debug", 5)) {
            level |= TJS_LOGLEVEL_DEBUG;
        } else if (0 == strncasecmp(tok, "error", 5)) {
            level |= TJS_LOGLEVEL_ERROR;
        }

        tok = strtok(NULL, ",");
    }

  free(tokens);

  return level;
}

/**
 * Fatal error handler
 *
 * @param[in]  userdata  Userdata added to heap
 * @param[in]  msg       Message to log
 **/

void tjs_fatal(void *userdata, const char *msg) {
    (void) userdata; ///< Not unused anymore..

    TJS_LOG_DUK("Fatal error on line: %s", (msg ? msg : "No message"));

    abort();
}

/**
 * Helper to dump the duktape stack
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_dump_stack(const char *func, int line, duk_context *ctx) {
    duk_push_context_dump(ctx);

    tjs_log(TJS_LOGLEVEL_DUK, func, line,
        "%s", duk_safe_to_string(ctx, -1));

    duk_pop(ctx);
}

/**
 * Terminate app
 **/

void tjs_exit() {
    duk_destroy_heap(touch.ctx);

    [NSApp terminate: NULL];
}

/******************************
 *             I/O            *
 ******************************/

/**
 * Read and eval file
 *
 * @param[in]  source  Name of file to load
 **/

static void tjs_eval_file(char *source) {
    TJS_LOG_INFO("Loading file %s", source);

    /* Load file */
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:
        [NSString stringWithUTF8String: source]];

    if (NULL == file) {
        TJS_LOG_ERROR("Failed to open file file %s", source);

        return;
    }

    /* Read and convert data */
    NSData *buffer = [file readDataToEndOfFile];
    NSString *data = [[NSString alloc] initWithData: buffer
        encoding: NSUTF8StringEncoding];

    [file closeFile];

    if (NULL != data) {
        /* Just eval the content */
        TJS_LOG_INFO("Eval'ing file %s", source);

        duk_eval_string_noresult(touch.ctx, (char *)[data UTF8String]);
    }
}

/**
 * Main entry point

 * @œparam{in}    argc  Number of arguments
 * @param[inout]  argv  Arguments array
 **/

int main(int argc, char *argv[]) {
    /* Create application */
    [NSAutoreleasePool new];
    [NSApplication sharedApplication];

    touch.loglevel = (TJS_LOGLEVEL_INFO|TJS_LOGLEVEL_DUK|TJS_LOGLEVEL_ERROR);

    tjs_embed_init();

    /* Create duk context */
    touch.ctx = duk_create_heap(NULL, NULL, NULL, NULL, tjs_fatal);

    /* Register objects */
    tjs_global_init(touch.ctx);
    tjs_command_init(touch.ctx);

    tjs_wm_init(touch.ctx);
    tjs_win_init(touch.ctx);
    tjs_screen_init(touch.ctx);

    tjs_scrubber_init(touch.ctx);
    tjs_label_init(touch.ctx);
    tjs_button_init(touch.ctx);
    tjs_slider_init(touch.ctx);

    /* Commandline arguments */
    int c, fileOptId = -1;

    while (-1 != (c = getopt(argc, argv, "df:hl:v"))) {
        switch (c) {
            case 'd': touch.loglevel |= TJS_LOGLEVEL_DEBUG; break;
            case 'f': fileOptId = optind - 1;               break;
            case 'h': tjs_usage();                          return 0;
            case 'l': touch.loglevel = tjs_level(optarg);   break;
            case 'v': tjs_version();                        return 0;
        }
    }

    /* Eval file after debug/loglevel is set */
    if (-1 != fileOptId) {
        tjs_eval_file(argv[fileOptId]);
    }

    /* Create and run application */
    AppDelegate *delegate = [[AppDelegate alloc] init];

    [NSApp setDelegate: delegate];
    [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
    [NSApp run];

    /* Tidy up */
    tjs_embed_deinit();
    tjs_exit();

    return 0;
}