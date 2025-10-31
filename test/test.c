#include "pulse/def.h"
#include "pulse/introspect.h"
#include "pulse/mainloop.h"
#include "string.h"
#include <pulse/pulseaudio.h>
#include <stdio.h>
#include <unistd.h>

typedef struct my_info {
    char *default_sink_name;
} my_info;

void callback(pa_context *context, const pa_server_info *server_info,
              void *userdata) {
    my_info *info = (my_info *) userdata;
    // strcpy(info->default_sink_name, server_info->default_sink_name);
    info->default_sink_name = (char *) server_info->default_sink_name;
}

void context_cb(pa_context *context, void *userdata) {
    switch (pa_context_get_state(context)) {
        case PA_CONTEXT_READY:
            *(int *)userdata = 1;
            break;
        case PA_CONTEXT_FAILED:
            *(int *)userdata = -1;
            break;
        case PA_CONTEXT_UNCONNECTED:
        case PA_CONTEXT_AUTHORIZING:
        case PA_CONTEXT_SETTING_NAME:
        case PA_CONTEXT_CONNECTING:
        case PA_CONTEXT_TERMINATED:
            break;
    }
}

int main() {
    int retval = 0;
    pa_mainloop *mainloop = pa_mainloop_new();
    pa_mainloop_api *mainloop_api = pa_mainloop_get_api(mainloop);
    pa_context *context = pa_context_new(mainloop_api, "WebRemote");

    int done = 0;
    int connect_ret = pa_context_connect(context, NULL, PA_CONTEXT_NOFLAGS, NULL);
    pa_context_set_state_callback(context, &context_cb, &done);
    printf("context_connect_ret: %d\n", connect_ret);

    while (!done) {
        int it = pa_mainloop_iterate(mainloop, 1, &retval);
        printf("iter: %d\n", it);
    }

    printf("%d\n", retval);
    // my_info *info = (my_info *) (mainloop_api->userdata);
    // info->default_sink_name = calloc(1000, 1);
    my_info info_d;
    my_info *info = &info_d;

    // pa_operation *op = pa_context_get_server_info(context, &callback,
    // mainloop_api->userdata);
    pa_operation *op = pa_context_get_server_info(context, &callback, info);

    while (pa_operation_get_state(op) == PA_OPERATION_RUNNING) {
        pa_mainloop_iterate(mainloop, 1, &retval);
        usleep(100);
    }
    // for (int i = 0; i < 10; i++) {
    //     sleep(2);
    printf("%s\n", info->default_sink_name);
    // }
}
