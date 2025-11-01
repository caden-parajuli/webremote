open Ctypes
module Types = Types_generated

module Functions (F : Ctypes.FOREIGN) = struct
  open F
  open Types

  let ( @|> ) args ret = args @-> returning ret
  let pa_mainloop_new = foreign "pa_mainloop_new" @@ void @|> ptr pa_mainloop
  let pa_mainloop_free = foreign "pa_mainloop_free" @@ ptr pa_mainloop @|> void

  let pa_mainloop_get_api =
    foreign "pa_mainloop_get_api" @@ ptr pa_mainloop @|> ptr pa_mainloop_api

  let pa_mainloop_iterate =
    foreign "pa_mainloop_iterate" @@ ptr pa_mainloop @-> int @-> ptr int @|> int

  let pa_operation_get_state =
    foreign "pa_operation_get_state"
    @@ ptr (const pa_operation)
    @|> pa_operation_state_t

  let pa_context_new =
    foreign "pa_context_new" @@ ptr pa_mainloop_api @-> string
    @|> ptr pa_context

  let pa_context_disconnect =
    foreign "pa_context_disconnect" @@ ptr pa_context @|> void

  let pa_context_unref = foreign "pa_context_unref" @@ ptr pa_context @|> void

  let pa_context_get_state =
    foreign "pa_context_get_state" @@ ptr pa_context @|> pa_context_state_t

  let pa_context_set_state_callback =
    foreign "pa_context_set_state_callback"
    @@ ptr pa_context
    @-> Foreign.funptr pa_context_notify_cb_t
    @-> ptr void @|> void

  let pa_context_connect =
    foreign "pa_context_connect"
    @@ ptr pa_context @-> string_opt @-> pa_context_flags_t
    @-> ptr_opt (const pa_spawn_api)
    @|> int

  let pa_context_get_server_info =
    foreign "pa_context_get_server_info"
    @@ ptr pa_context
    @-> Foreign.funptr pa_server_info_cb_t
    @-> ptr void @|> ptr pa_operation

  let pa_context_get_sink_info_by_name =
    foreign "pa_context_get_sink_info_by_name"
    @@ ptr pa_context @-> string @-> pa_sink_info_cb_t @-> ptr void
    @|> ptr pa_operation

  let pa_cvolume_avg =
    foreign "pa_cvolume_avg" @@ ptr (const pa_cvolume) @|> pa_volume_t

  let pa_cvolume_scale =
    foreign "pa_cvolume_scale" @@ ptr pa_cvolume @-> pa_volume_t
    @|> ptr_opt pa_cvolume

  let pa_cvolume_inc =
    foreign "pa_cvolume_inc" @@ ptr pa_cvolume @-> pa_volume_t
    @|> ptr_opt pa_cvolume

  let pa_cvolume_dec =
    foreign "pa_cvolume_dec" @@ ptr pa_cvolume @-> pa_volume_t
    @|> ptr_opt pa_cvolume

  let pa_context_set_sink_volume_by_name =
    foreign "pa_context_set_sink_volume_by_name"
    @@ ptr pa_context @-> string
    @-> ptr (const pa_cvolume)
    @-> pa_context_success_cb_t @-> ptr void @|> ptr pa_operation
end
