open Ctypes
module Types = Types_generated

module Functions (F : Ctypes.FOREIGN) = struct
  open F
  open Types

  let ( @|> ) args ret = args @-> returning ret

  let dbus_bus_get =
    foreign "dbus_bus_get" @@ dbus_bus_type @-> ptr_opt dbus_error
    @|> ptr_opt dbus_connection

  let dbus_connection_set_exit_on_disconnect =
    foreign "dbus_connection_set_exit_on_disconnect"
    @@ ptr dbus_connection @-> dbus_bool_t @|> void

  let dbus_connection_unref =
    foreign "dbus_connection_unref" @@ ptr dbus_connection @|> void

  let dbus_message_new_method_call =
    foreign "dbus_message_new_method_call"
    @@ string @-> string @-> string @-> string @|> ptr dbus_message

  let dbus_message_new_signal =
    foreign "dbus_message_new_signal"
    @@ string @-> string @-> string @|> ptr dbus_message

  let dbus_message_unref =
    foreign "dbus_message_unref" @@ ptr dbus_message @|> void

  (* connection -> message -> timeout_ms -> error -> response *)
  let dbus_connection_send_with_reply_and_block =
    foreign "dbus_connection_send_with_reply_and_block"
    @@ ptr dbus_connection @-> ptr dbus_message @-> int @-> ptr_opt dbus_error
    @|> ptr dbus_message

  let dbus_message_append_arg =
    foreign "dbus_message_append_args"
    @@ ptr dbus_message @-> int @-> ptr void @|> dbus_bool_t
  (* This is actually a varargs function *)

  let dbus_connection_send =
    foreign "dbus_connection_send"
    @@ ptr dbus_connection @-> ptr dbus_message @-> ptr uint32_t @|> dbus_bool_t

  let dbus_message_get_type =
    foreign "dbus_message_get_type" @@ ptr dbus_message @|> int

  let dbus_message_get_signature =
    foreign "dbus_message_get_signature" @@ ptr dbus_message @|> string

  let dbus_message_iter_init =
    foreign "dbus_message_iter_init"
    @@ ptr dbus_message @-> ptr dbus_message_iter @|> dbus_bool_t

  let dbus_message_iter_has_next =
    foreign "dbus_message_iter_has_next"
    @@ ptr dbus_message_iter @|> dbus_bool_t

  let dbus_message_iter_next =
    foreign "dbus_message_iter_next" @@ ptr dbus_message_iter @|> dbus_bool_t

  let dbus_message_iter_get_arg_type =
    foreign "dbus_message_iter_get_arg_type" @@ ptr dbus_message_iter @|> int

  let dbus_message_iter_get_signature =
    foreign "dbus_message_iter_get_signature"
    @@ ptr dbus_message_iter @|> string

  let dbus_message_iter_get_element_type =
    foreign "dbus_message_iter_get_element_type"
    @@ ptr dbus_message_iter @|> int

  let dbus_message_iter_recurse =
    foreign "dbus_message_iter_recurse"
    @@ ptr dbus_message_iter @-> ptr dbus_message_iter @|> void

  let dbus_message_iter_get_basic =
    foreign "dbus_message_iter_get_basic"
    @@ ptr dbus_message_iter @-> ptr void @|> void
end
