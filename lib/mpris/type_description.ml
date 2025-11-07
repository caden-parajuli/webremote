open Ctypes

module Types (F : Ctypes.TYPE) = struct
  open F

  type dbus_bus_type =
    | DBUS_BUS_SESSION
    | DBUS_BUS_SYSTEM
    | DBUS_BUS_STARTER

  let dbus_bus_session = constant "DBUS_BUS_SESSION" int64_t
  let dbus_bus_system = constant "DBUS_BUS_SYSTEM" int64_t
  let dbus_bus_starter = constant "DBUS_BUS_STARTER" int64_t

  let dbus_bus_type =
    enum ~typedef:true "DBusBusType"
      [
        (DBUS_BUS_SESSION, dbus_bus_session);
        (DBUS_BUS_SYSTEM, dbus_bus_system);
        (DBUS_BUS_STARTER, dbus_bus_starter);
      ]

  (* "other types are allowed and all code must silently ignore messages
     of unknown type. #DBUS_MESSAGE_TYPE_INVALID will never be returned." *)
  let dbus_message_type_invalid = constant "DBUS_MESSAGE_TYPE_INVALID" int

  let dbus_message_type_method_call =
    constant "DBUS_MESSAGE_TYPE_METHOD_CALL" int

  let dbus_message_type_method_return =
    constant "DBUS_MESSAGE_TYPE_METHOD_RETURN" int

  let dbus_message_type_error = constant "DBUS_MESSAGE_TYPE_ERROR" int
  let dbus_message_type_signal = constant "DBUS_MESSAGE_TYPE_SIGNAL" int
  let dbus_num_message_types = constant "DBUS_NUM_MESSAGE_TYPES" int

  type dbus_connection

  let dbus_connection : dbus_connection structure typ =
    structure "DBusConnection"

  type dbus_error

  let dbus_error : dbus_error structure typ = structure "DBusError"
  let error_name = field dbus_error "name" string
  let error_message = field dbus_error "message" string
  (* Incomplete, Ctypes does not support bitfields *)

  type dbus_message

  let dbus_message : dbus_message structure typ = structure "DBusMessage"
  (* Incomplete, Ctypes does not support bitfields *)

  let dbus_bool_t = uint32_t

  let dbus_timeout_use_default = constant "DBUS_TIMEOUT_USE_DEFAULT" int

type dbus_type =
    | Dbus_type_invalid
    | Dbus_type_byte
    | Dbus_type_boolean
    | Dbus_type_int16
    | Dbus_type_uint16
    | Dbus_type_int32
    | Dbus_type_uint32
    | Dbus_type_int64
    | Dbus_type_uint64
    | Dbus_type_double
    | Dbus_type_string
    | Dbus_type_object_path
    | Dbus_type_signature
    | Dbus_type_unix_fd
    | Dbus_type_array
    | Dbus_type_variant
    | Dbus_type_struct
    | Dbus_type_dict_entry


  let dbus_type_invalid = constant "DBUS_TYPE_INVALID" int
  let dbus_type_byte = constant "DBUS_TYPE_BYTE" int
  let dbus_type_boolean = constant "DBUS_TYPE_BOOLEAN" int
  let dbus_type_int16 = constant "DBUS_TYPE_INT16" int
  let dbus_type_uint16 = constant "DBUS_TYPE_UINT16" int
  let dbus_type_int32 = constant "DBUS_TYPE_INT32" int
  let dbus_type_uint32 = constant "DBUS_TYPE_UINT32" int
  let dbus_type_int64 = constant "DBUS_TYPE_INT64" int
  let dbus_type_uint64 = constant "DBUS_TYPE_UINT64" int
  let dbus_type_double = constant "DBUS_TYPE_DOUBLE" int
  let dbus_type_string = constant "DBUS_TYPE_STRING" int
  let dbus_type_object_path = constant "DBUS_TYPE_OBJECT_PATH" int
  let dbus_type_signature = constant "DBUS_TYPE_SIGNATURE" int
  let dbus_type_unix_fd = constant "DBUS_TYPE_UNIX_FD" int
  let dbus_type_array = constant "DBUS_TYPE_ARRAY" int
  let dbus_type_variant = constant "DBUS_TYPE_VARIANT" int
  let dbus_type_struct = constant "DBUS_TYPE_STRUCT" int
  let dbus_type_dict_entry = constant "DBUS_TYPE_DICT_ENTRY" int
  let dbus_number_of_types = constant "DBUS_NUMBER_OF_TYPES" int

  type dbus_message_iter
  let dbus_message_iter : dbus_message_iter structure typ = structure "DBusMessageIter"
  let iter_dummy1 = field dbus_message_iter "dummy1" (ptr void)
  let iter_dummy2 = field dbus_message_iter "dummy2" (ptr void)
  let iter_dummy3 = field dbus_message_iter "dummy3" uint32_t
  let iter_dummy4 = field dbus_message_iter "dummy4" int 
  let iter_dummy5 = field dbus_message_iter "dummy5" int 
  let iter_dummy6 = field dbus_message_iter "dummy6" int 
  let iter_dummy7 = field dbus_message_iter "dummy7" int 
  let iter_dummy8 = field dbus_message_iter "dummy8" int 
  let iter_dummy9 = field dbus_message_iter "dummy9" int 
  let iter_dummy10 = field dbus_message_iter "dummy10" int 
  let iter_dummy11 = field dbus_message_iter "dummy11" int 
  let iter_pad1 = field dbus_message_iter "pad1" int 
  let iter_pad2 = field dbus_message_iter "pad2" int 
  let iter_pad3 = field dbus_message_iter "pad3" (ptr void)
  let () = seal dbus_message_iter

  let dbus_false = constant "FALSE" uint32_t
  let dbus_true = constant "TRUE" uint32_t

end
