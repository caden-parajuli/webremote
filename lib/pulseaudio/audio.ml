type pa_mainloop = C.Type.pa_mainloop Ctypes.structure Ctypes.ptr
type pa_context = C.Type.pa_context Ctypes.structure Ctypes.ptr

type s = {
  mainloop : pa_mainloop;
  context : pa_context;
  sink_name : string;
}

let ( let* ) = Option.bind

let iterate mainloop op =
  let open C.Functions in
  let mainloop_ret = Ctypes.allocate Ctypes.int 0 in
  let iter_ret = ref 0 in
  let op_state = ref C.Type.PA_OPERATION_RUNNING in
  let () =
    while
      !op_state = C.Type.PA_OPERATION_RUNNING
      && !iter_ret >= 0
      && Ctypes.(!@mainloop_ret) >= 0
    do
      iter_ret := pa_mainloop_iterate mainloop 1 mainloop_ret;
      Thread.delay 0.0001;
      op_state := pa_operation_get_state op
    done
  in
  if !iter_ret < 0 || Ctypes.(!@mainloop_ret) < 0 then
    false
  else
    let open C.Type in
    match !op_state with
    | PA_OPERATION_DONE -> true
    | PA_OPERATION_CANCELLED -> false
    (* unreachable *)
    | PA_OPERATION_RUNNING -> assert false

let new_context mainloop mainloop_api =
  let open C.Functions in

  let context = pa_context_new mainloop_api "WebRemote" in
  Gc.finalise (fun c -> pa_context_unref c) context;

  (* We need a callback to tell us when context is connected *)
  let is_done = Ctypes.allocate Ctypes.bool false in
  let success = Ctypes.allocate Ctypes.bool false in
  let state_cb context data =
    let open Ctypes in
    match pa_context_get_state context with
    | C.Type.PA_CONTEXT_READY ->
        is_done <-@ true;
        success <-@ true
    | C.Type.PA_CONTEXT_FAILED ->
        is_done <-@ true;
        success <-@ false
    | _ -> ()
  in
  let () =
    pa_context_set_state_callback context state_cb
      (Ctypes.to_voidp is_done)
  in

  if pa_context_connect context None C.Type.PA_CONTEXT_NOFLAGS None < 0 then
    None
  else
    (* Have to iterate the mainloop until the context is connected *)
    let mainloop_ret = Ctypes.allocate Ctypes.int 0 in
    let () =
      while not Ctypes.(!@is_done) do
        if pa_mainloop_iterate mainloop 1 mainloop_ret < 0 then (
          let open Ctypes in
          is_done <-@ true;
          success <-@ false)
        else
          ()
      done
    in
    if Ctypes.(!@mainloop_ret < 0 || not !@success) then
      None
    else
      Some context

let get_default_sink_name mainloop context =
  let open C.Functions in
  let open Ctypes in
  let sink_name = allocate string "" in

  let server_info_cb context server_info data =
    let name_ptr = from_voidp string data in
    name_ptr <-@ getf !@server_info C.Type.default_sink_name
  in
  let op =
    pa_context_get_server_info context server_info_cb
    @@ to_voidp sink_name
  in

  match iterate mainloop op with
  | true -> Some !@sink_name
  | false -> None

let init () =
  let open C.Functions in
  let mainloop = pa_mainloop_new () in
  let mainloop_api = pa_mainloop_get_api mainloop in

  let* context = new_context mainloop mainloop_api in
  let* sink_name = get_default_sink_name mainloop context in

  Some { mainloop; context; sink_name }

let close s =
  let open C.Functions in
  let () = pa_context_disconnect s.context in
  let () = pa_context_unref s.context in
  let () = pa_mainloop_free s.mainloop in
  ()

(* Array memcpy. Throws exception if array lengths are not equal *)
let arrcpy (dest : 'a Ctypes.carray) (src : 'a Ctypes.carray) =
  let open Ctypes in
  assert (dest.alength = src.alength);

  for i = 0 to dest.alength - 1 do
    dest.astart +@ i <-@ !@(src.astart +@ i)
  done

let int_of_volume_t volume =
  int_of_float @@ Float.round
  @@ 100.0
     *. (float_of_int @@ Unsigned.UInt32.to_int volume)
     /. float_of_int C.Type.pa_volume_norm

let volume_t_of_int volume =
  Unsigned.UInt32.of_int @@ int_of_float
  @@ Float.round
       (float_of_int volume *. float_of_int C.Type.pa_volume_norm /. 100.0)

let get_volume_struct s =
  let open C.Functions in
  let open C.Type in
  let open Ctypes in
  let cvolume = allocate_n pa_cvolume ~count:1 in

  let sink_info_cb context sink_info eol data =
    if eol <> 0 then
      ()
    else
      let out_ptr = from_voidp pa_cvolume data in
      let cvolume = getf !@sink_info volume in

      let out_channels = out_ptr |-> volume_channels in
      let out_values = getf !@out_ptr values in

      (* Have to do a deep copy per PulseAudio docs *)
      out_channels <-@ getf cvolume volume_channels;
      arrcpy out_values (getf cvolume values)
  in
  let op =
    pa_context_get_sink_info_by_name s.context s.sink_name sink_info_cb
      (to_voidp cvolume)
  in
  match iterate s.mainloop op with
  | true -> Some cvolume
  | false -> None

let get_volume s =
  match get_volume_struct s with
  | None -> None
  | Some cvolume ->
      let volume = C.Functions.pa_cvolume_avg cvolume in

      Some (int_of_volume_t volume)

let set_volume_struct s cvolume =
  let open Ctypes in
  let open C.Functions in
  let success = Ctypes.allocate Ctypes.int 0 in
  let context_success_cb _context op_success _data = success <-@ op_success in
  let op =
    pa_context_set_sink_volume_by_name s.context s.sink_name cvolume
      context_success_cb Ctypes.null
  in

  iterate s.mainloop op

let set_volume s volume =
  let open C.Functions in
  let* cvolume = get_volume_struct s in
  let* new_cvolume = pa_cvolume_scale cvolume (volume_t_of_int volume) in

  let success = set_volume_struct s new_cvolume in

  match success with
  | false -> None
  | true -> Some (int_of_volume_t @@ pa_cvolume_avg new_cvolume)

let raise_volume s by =
  let open C.Functions in
  let* cvolume = get_volume_struct s in
  let* new_cvolume = pa_cvolume_inc cvolume (volume_t_of_int by) in

  let success = set_volume_struct s new_cvolume in

  match success with
  | false -> None
  | true -> Some (int_of_volume_t @@ pa_cvolume_avg new_cvolume)

let lower_volume s by =
  let open C.Functions in
  let* cvolume = get_volume_struct s in
  let* new_cvolume = pa_cvolume_dec cvolume (volume_t_of_int by) in

  let success = set_volume_struct s new_cvolume in

  match success with
  | false -> None
  | true -> Some (int_of_volume_t @@ pa_cvolume_avg new_cvolume)
