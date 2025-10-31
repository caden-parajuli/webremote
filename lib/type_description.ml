open Ctypes
open Foreign

module Types (F : Ctypes.TYPE) = struct
  open F

  (* These should be enums, but we don't actually need it *)
  let pa_sample_format = int64_t
  let pa_channel_position = int64_t
  let pa_sink_flags_t = int64_t

  type pa_context_flags_t =
    | PA_CONTEXT_NOFLAGS
    | PA_CONTEXT_NOAUTOSPAWN
    | PA_CONTEXT_NOFAIL

  let pa_context_noflags = constant "PA_CONTEXT_NOFLAGS" int64_t
  let pa_context_noautospawn = constant "PA_CONTEXT_NOAUTOSPAWN" int64_t
  let pa_context_nofail = constant "PA_CONTEXT_NOFAIL" int64_t

  let pa_context_flags_t =
    enum ~typedef:true "pa_context_flags_t"
      [
        (PA_CONTEXT_NOFLAGS, pa_context_noflags);
        (PA_CONTEXT_NOAUTOSPAWN, pa_context_noautospawn);
        (PA_CONTEXT_NOFAIL, pa_context_nofail);
      ]

  type pa_context_state_t =
    | PA_CONTEXT_UNCONNECTED
    | PA_CONTEXT_CONNECTING
    | PA_CONTEXT_AUTHORIZING
    | PA_CONTEXT_SETTING_NAME
    | PA_CONTEXT_READY
    | PA_CONTEXT_FAILED
    | PA_CONTEXT_TERMINATED

  let pa_context_unconnected = constant "PA_CONTEXT_UNCONNECTED" int64_t
  let pa_context_connecting = constant "PA_CONTEXT_CONNECTING" int64_t
  let pa_context_authorizing = constant "PA_CONTEXT_AUTHORIZING" int64_t
  let pa_context_setting_name = constant "PA_CONTEXT_SETTING_NAME" int64_t
  let pa_context_ready = constant "PA_CONTEXT_READY" int64_t
  let pa_context_failed = constant "PA_CONTEXT_FAILED" int64_t
  let pa_context_terminated = constant "PA_CONTEXT_TERMINATED" int64_t

  let pa_context_state_t =
    enum ~typedef:true "pa_context_state_t"
      [
        (PA_CONTEXT_UNCONNECTED, pa_context_unconnected);
        (PA_CONTEXT_CONNECTING, pa_context_connecting);
        (PA_CONTEXT_AUTHORIZING, pa_context_authorizing);
        (PA_CONTEXT_SETTING_NAME, pa_context_setting_name);
        (PA_CONTEXT_READY, pa_context_ready);
        (PA_CONTEXT_FAILED, pa_context_failed);
        (PA_CONTEXT_TERMINATED, pa_context_terminated);
      ]

  type pa_context

  let pa_context : pa_context structure typ = structure "pa_context"
  let pa_context_notify_cb_t = ptr pa_context @-> ptr void @-> returning void

  type pa_operation

  let pa_operation : pa_operation structure typ = structure "pa_operation"

  type pa_operation_state_t =
    | PA_OPERATION_RUNNING
    | PA_OPERATION_DONE
    | PA_OPERATION_CANCELLED

  let pa_operation_running = constant "PA_OPERATION_RUNNING" int64_t
  let pa_operation_done = constant "PA_OPERATION_DONE" int64_t
  let pa_operation_cancelled = constant "PA_OPERATION_CANCELLED" int64_t

  let pa_operation_state_t =
    enum ~typedef:true "pa_operation_state_t"
      [
        (PA_OPERATION_RUNNING, pa_operation_running);
        (PA_OPERATION_DONE, pa_operation_done);
        (PA_OPERATION_CANCELLED, pa_operation_cancelled);
      ]

  (* let pa_channels_max = constant "PA_CHANNELS_MAX" uint *)
  let pa_channels_max = 32

  type pa_channel_map

  let pa_channel_map : pa_channel_map structure typ = structure "pa_channel_map"
  let channels = field pa_channel_map "channels" uint8_t

  let map =
    field pa_channel_map "map" (array pa_channels_max pa_channel_position)

  type pa_sample_spec

  let pa_sample_spec : pa_sample_spec structure typ = structure "pa_sample_spec"
  let format = field pa_sample_spec "format" pa_sample_format
  let rate = field pa_sample_spec "rate" uint32_t
  let channels = field pa_sample_spec "channels" uint8_t
  let () = seal (pa_sample_spec : pa_sample_spec structure typ)

  type pa_server_info

  let pa_server_info : pa_server_info structure typ = structure "pa_server_info"
  let user_name = field pa_server_info "user_name" string
  let host_name = field pa_server_info "host_name" string
  let server_version = field pa_server_info "server_version" string
  let server_name = field pa_server_info "server_name" string
  let sample_spec = field pa_server_info "sample_spec" pa_sample_spec
  let default_sink_name = field pa_server_info "default_sink_name" string
  let default_source_name = field pa_server_info "default_source_name" string
  let cookie = field pa_server_info "cookie" uint32_t
  let channel_map = field pa_server_info "channel_map" pa_channel_map
  let () = seal (pa_server_info : pa_server_info structure typ)
  let void_void_fun = funptr (void @-> returning void)

  type pa_spawn_api

  let pa_spawn_api : pa_spawn_api structure Ctypes.typ =
    Ctypes.structure "pa_spawn_api"

  let prefork = Ctypes.field pa_spawn_api "prefork" void_void_fun
  let postfork = Ctypes.field pa_spawn_api "postfork" void_void_fun
  let atfork = Ctypes.field pa_spawn_api "atfork" void_void_fun
  let () = Ctypes.seal pa_spawn_api

  let pa_server_info_cb_t =
    ptr pa_context
    @-> ptr (const pa_server_info)
    @-> ptr void @-> returning void

  type pa_proplist

  let pa_proplist : pa_proplist structure typ = structure "pa_proplist"

  type pa_mainloop

  let pa_mainloop : pa_mainloop structure typ = structure "pa_mainloop"

  type pa_mainloop_api

  let pa_mainloop_api : pa_mainloop_api structure typ =
    structure "pa_mainloop_api"

  let userdata = field pa_mainloop_api "userdata" @@ ptr void
  let io_new = field pa_mainloop_api "io_new" @@ ptr void
  let io_enable = field pa_mainloop_api "io_enable" @@ ptr void
  let io_free = field pa_mainloop_api "io_free" @@ ptr void
  let io_set_destroy = field pa_mainloop_api "io_set_destroy" @@ ptr void
  let time_new = field pa_mainloop_api "time_new" @@ ptr void
  let time_restart = field pa_mainloop_api "time_restart" @@ ptr void
  let time_free = field pa_mainloop_api "time_free" @@ ptr void
  let time_set_destroy = field pa_mainloop_api "time_set_destroy" @@ ptr void
  let defer_new = field pa_mainloop_api "defer_new" @@ ptr void
  let defer_enable = field pa_mainloop_api "defer_enable" @@ ptr void
  let defer_free = field pa_mainloop_api "defer_free" @@ ptr void
  let defer_set_destroy = field pa_mainloop_api "defer_set_destroy" @@ ptr void
  let quit = field pa_mainloop_api "quit" @@ ptr void

  type pa_cvolume

  let pa_volume_t = uint32_t
  let pa_usec_t = uint64_t
  let pa_cvolume : pa_cvolume structure typ = structure "pa_cvolume"
  let volume_channels = field pa_cvolume "channels" uint8_t
  let values = field pa_cvolume "values" @@ array pa_channels_max pa_volume_t
  let () = seal pa_cvolume

  type pa_sink_state_t = 
    | PA_SINK_INVALID_STATE
    | PA_SINK_RUNNING
    | PA_SINK_SUSPENDED
  let pa_sink_invalid_state = constant "PA_SINK_INVALID_STATE" int64_t
  let pa_sink_running = constant "PA_SINK_RUNNING" int64_t
  let pa_sink_idle = constant "PA_SINK_IDLE" int64_t
  let pa_sink_suspended = constant "PA_SINK_SUSPENDED" int64_t
  let pa_sink_state_t = enum ~typedef:true "pa_sink_state_t" [
    PA_SINK_INVALID_STATE, pa_sink_invalid_state;
    PA_SINK_RUNNING, pa_sink_running;
    PA_SINK_SUSPENDED, pa_sink_suspended;
  ]

  type pa_sink_port_info
  let pa_sink_port_info : pa_sink_port_info structure typ = structure "pa_sink_port_info"

  type pa_format_info
  let pa_format_info : pa_format_info structure typ = structure "pa_format_info"


  type pa_sink_info

  let pa_sink_info : pa_sink_info structure typ = structure "pa_sink_info"
  let name = field pa_sink_info "name" string
  let index = field pa_sink_info "index" uint32_t
  let description = field pa_sink_info "description" string
  let sample_spec = field pa_sink_info "sample_spec" pa_sample_spec
  let channel_map = field pa_sink_info "channel_map" pa_channel_map
  let owner_module = field pa_sink_info "owner_module" uint32_t
  let volume = field pa_sink_info "volume" pa_cvolume
  let mute = field pa_sink_info "mute" int
  let monitor_source = field pa_sink_info "monitor_source" uint32_t
  let monitor_source_name = field pa_sink_info "monitor_source_name" string
  let latency = field pa_sink_info "latency" pa_usec_t
  let driver = field pa_sink_info "driver" string
  let flags = field pa_sink_info "flags" pa_sink_flags_t
  let proplist = field pa_sink_info "proplist" @@ ptr pa_proplist
  let configured_latency = field pa_sink_info "configured_latency" pa_usec_t
  let base_volume = field pa_sink_info "base_volume" pa_volume_t
  let state = field pa_sink_info "state" pa_sink_state_t
  let n_volume_steps = field pa_sink_info "n_volume_steps" uint32_t
  let card = field pa_sink_info "card" uint32_t
  let n_ports = field pa_sink_info "n_ports" uint32_t
  let ports = field pa_sink_info "ports" @@ ptr @@ ptr pa_sink_port_info
  let active_port = field pa_sink_info "active_port" @@ ptr pa_sink_port_info
  let n_formats = field pa_sink_info "n_formats" uint8_t
  let formats = field pa_sink_info "formats" @@ ptr @@ ptr pa_format_info
  let () = seal pa_sink_info

  let pa_sink_info_cb_t = funptr @@ ptr pa_context @-> ptr (const pa_sink_info) @-> int @-> ptr void @-> returning void

  let pa_volume_norm = constant "PA_VOLUME_NORM" int

  let pa_context_success_cb_t = funptr @@ ptr pa_context @-> int @-> ptr void @-> returning void
end
