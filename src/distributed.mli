open Batteries

(** This module provides a type representing a node id. *) 
module NodeId : sig

  type t
  (** The abstract type representing a node id. *)  

  val get_name : t -> string
  (** [get_name node] returns the name of the node. *)  
end

(** This module provides a type representing a process id. *)
module ProcessId : sig

  type t
  (** The abstract type representing a process id. *)
end

(** Abstract type which can perform monadic concurrent IO. *)
module type NonBlockIO = sig

  type 'a t
  (** The monadic light weight thread type returning value ['a]. *)

  type 'a stream
  (** An unbounded stream holding values of ['a]. *)

  type input_channel
  (** A type to represent a non-blocking input channel *)

  type output_channel
  (** A type to represent a non-blocking output channel *)    

  type server
  (** A type to represent a server *)

  type logger
  (** A type to represent a logger *)

  exception Timeout
  (** Exception raised by time out operations *)

  type level = Debug 
             | Info
             | Notice
             | Warning
             | Error
             | Fatal
  (** Type to represent levels of a log message. *)

  val lib_name : string
  (** The name of the implementation, for logging purposes. *)

  val lib_version : string
  (** The version implementation, for logging purposes. *)

  val lib_description : string 
  (** A description of the implementation (e.g., the url of the code repository ), for logging purposes. *)

  val return : 'a -> 'a t
  (** [return v] creates a light weight thread returning [v]. *)			  

  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  (** [bind t f] is a thread which first waits for the thread [t] to terminate and then, if the thread succeeds, 
      behaves as the application of function [f] to the return value of [t]. If the thread [t] fails, [bind t f] also fails, 
      with the same exception. 
  *)

  val ignore_result : 'a t -> unit
  (** [ignore_result t] is like Pervasives.ignore t except that:
      if [t] already failed, it raises the exception now,
      if [t] is sleeping and fails later, the exception will be given to ​async_exception_hook.
  *)	

  val fail : exn -> 'a t
  (** [fail e] is a thread that fails with the exception [e]. *)

  val catch : (unit -> 'a t) -> (exn -> 'a t) -> 'a t
  (** [catch t f] is a thread that behaves as the thread [t ()] if this thread succeeds. 
      If the thread [t ()] fails with some exception, [catch t f] behaves as the application of [f] to this exception. 
  *)

  val async : (unit -> 'a t) -> unit
  (** [async f starts] a thread without waiting for the result. *)                 

  val create_stream : unit -> 'a stream * ('a option -> unit)
  (** [create ()] returns a new stream and a push function. *)

  val get : 'a stream -> 'a option t
  (** [get st] removes and returns the first element of the stream, if any. Will block if the stream is empty. *)

  val stream_append : 'a stream -> 'a stream -> 'a stream 
  (** [stream_append s1 s2] returns a [stream] which returns all elements of [s1], then all elements of [s2]. *)    

  val close_input : input_channel -> unit t
  (** [close ch] closes the given channel immediately. *)

  val close_output : output_channel -> unit t
  (** [close ch] closes the given channel. It performs all pending actions, flushes it and closes it. *)

  val read_value : input_channel -> 'a t
  (** [read_value ic] reads a marshalled value from [ic]. *)

  val write_value : output_channel -> ?flags:Marshal.extern_flags list -> 'a -> unit t
  (** [write_value oc ?flags x] marshals the value [x] to [oc]. *)

  val open_connection : Unix.sockaddr -> (input_channel * output_channel) t
  (** [open_connection addr] opens a connection to the given address and returns two channels for using it. *)

  val establish_server : ?backlog:int -> Unix.sockaddr -> (input_channel * output_channel -> unit) -> server
  (** [establish_server ?backlog sockaddr f] creates a server which will listen for incoming connections. 
      New connections are passed to [f]. Note that [f] must not raise any exception. Backlog is the argument passed to Lwt_unix.listen.
  *)

  val shutdown_server : server -> unit
  (** [shutdown_server server] will shutdown [server]. *)    

  val log : ?exn:exn -> ?location:string * int * int -> logger:logger -> level:level -> string -> unit t
  (** [log ?exn ?location logger level message] logs a message using [logger].        
      If exn is provided, then its string representation (= Printexc.to_string exn) will be append to the message, 
      and if possible the back trace will also be logged. Location contains the location of the logging directive, 
      it is of the form (file_name, line, column).
  *)     

  val sleep : float -> unit t
  (** [sleep d] is a thread that remains suspended for [d] seconds and then terminates. *)

  val timeout : float -> 'a t
  (** [timeout d] is a thread that remains suspended for [d] seconds and then fails with ​Timeout. *)

  val choose : 'a t list -> 'a t
  (** [choose l] behaves as the first thread in [l] to terminate. If several threads are already terminated, one is chosen at random. *)

  val pick : 'a t list -> 'a t
  (** [pick l] is the same as [​choose], except that it cancels all sleeping threads when one terminates. *)

  val nchoose : 'a t list -> 'a list t
  (** [nchoose l] returns the value of all that have successfully terminated. If all threads are sleeping, 
       it waits for at least one to terminates. If one the threads of [l] fails, [nchoose] fails with the same exception.          
  *)         

  val at_exit : (unit -> unit t) -> unit
  (** [at_exit fn] will call fn on program exit. *)

end

(** The abstract type representing the messages that will be sent between processes. *)
module type Message_type = sig

  type t
  (** Abstract type representing the messages that will be sent between processes. *)

  val string_of_message : t -> string
  (** [string_of_message msg] returns the [string] representation of [msg]. *)
end

(** A unit of computation which can be executed on a remote host. *)
module Process : sig

  module type S = sig
    exception Init_more_than_once
    (** Exception that is raised if [bootstrap] is called more than once. *)

    exception Empty_matchers
    (** Exception that is raised if [receive] is called with an empty matchers list. *)

    exception InvalidNode of NodeId.t
    (** Exception that is raised when [spawn], [broadcast], [monitor] are called with an invalid node or if [send]
        is called with a process which resides on an unknown node.
    *)

    exception Local_only_mode
    (** Exception that is raised when [add_remote_node] or [remove_remote_node] is called on a node that is operating in local only mode. *)        

    type 'a t
    (** The abstract monadic type representing a computation returning ['a]. *)

    type 'a io 
    (** Abstract type for monadic concurrent IO returning ['a]. *)        

    type message_type
    (** The abstract type representing the messages that will be sent between processes. *) 

    type 'a matcher
    (** The abstract type representing a matcher to be used with [receive] function. *)  

    type monitor_ref
    (** The abstract type representing a monitor_ref that is returned when a processes is monitored and can be used to unmonitor it. *)   

    type logger
    (** The abstract type representing the logger to be used. *)         

    type monitor_reason = Normal of ProcessId.t                  (** Process terminated normally. *)
                        | Exception of ProcessId.t * exn         (** Process terminated with exception. *)
                        | UnkownNodeId of ProcessId.t * NodeId.t (** An operation failed because the remote node id is unknown. *)
                        | NoProcess of ProcessId.t               (** Attempted to monitor a process that does not exist. *)
    (** Reason for process termination. *)              

    (** The configuration of a node to be run as a remote node i.e., one that can both send an receive messages with other nodes. *)
    module Remote_config : sig
      type t = { remote_nodes         : (string * int * string) list ; (** The initial list of remote nodes which this node can send messages to. A list of external ip address/port/node name triplets.*)
                 local_port           : int                          ; (** The port that this node should run on. *)
                 heart_beat_timeout   : float                        ; (** The maximum amount of time in seconds to wait between heart beats from remote nodes before marking them as unavailable. *)
                 heart_beat_frequency : float                        ; (** The amount of time between sending hearts to nodes that are connected to this node. *) 
                 connection_backlog   : int                          ; (** The the argument used when listening on a socket. *)
                 node_name            : string                       ; (** The name of this node. *) 
                 node_ip              : string                       ; (** The external ip address of this node. *)
                 logger               : logger                       ; (** The logger that should be used. *) 
               }    
    end                 

    (** The configuration of a node to be run as a local node i.e., one that can not send or receive messages with other nodes. *)
    module Local_config : sig
      type t = { node_name          : string ; (** The name of this node. *) 
                 logger             : logger ; (** The logger that should be used. *)
               }
    end

    type node_config = Local of Local_config.t
                     | Remote of Remote_config.t
    (** The configuration of a node. Can be one of [Local_only] or [Remote]. *)                                    

    val return : 'a -> 'a t
    (** [return v] creates a computation returning [v]. *)

    val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
    (** [c >>= f] is a computation which first waits for the computation [c] to terminate and then, if the computation succeeds, 
        behaves as the application of function [f] to the return value of [c]. If the computation [c] fails, [c >>= f] also fails, 
        with the same exception. 
    *)

    val fail : exn -> 'a t
    (** [fail e] is a process that fails with the exception [e]. *)

    val catch : (unit -> 'a t) -> (exn -> 'a t) -> 'a t
    (** [catch p f] is a process that behaves as the process [p ()] if this process succeeds. 
        If the process [p ()] fails with some exception, [catch p f] behaves as the application of [f] to this exception. 
    *)

    val spawn : ?monitor:bool -> NodeId.t -> unit t -> (ProcessId.t * monitor_ref option) t
    (** [spawn monitor name node_id process] will spawn [process] on [node_id] returning the [ProcessId.t] associated with the newly spawned process.
        If [monitor] is true (default value is false) then the spawned process will also be monitored and the associated [monitor_ref] will be 
        returned. 

        If [node_id] is an unknown node then [InvalidNode] exception is raised.
    *) 

    val case : (message_type -> bool) -> (message_type -> 'a t) -> 'a matcher
    (** [case match_fn handler] will create a [matcher] which will use [match_fn] to match on potential messages and [handler]
        to process the matched message .
    *)

    val termination_case : (monitor_reason -> 'a t) -> 'a matcher
    (** [termination_case handler] will create a [matcher] which can use used to match against [termination_reason] for a 
        process that is being monitored. If this process is monitoring another process then providing this matcher in the list
        of matchers to [receive] will allow this process to act on the termination of the monitored process.

        NOTE : when a remote process (i.e., one running on another node) raises an exception you will not be able 
        to pattern match on the exception . This is a limitation of the Marshal OCaml module : 
        " Values of extensible variant types, for example exceptions (of extensible type exn), returned by the unmarshaller 
          should not be pattern-matched over through [match ... with] or [try ... with], because unmarshalling does not preserve the 
          information required for matching their constructors. Structural equalities with other extensible variant values does not work either. 
          Most other uses such as Printexc.to_string, will still work as expected. "

        See http://caml.inria.fr/pub/docs/manual-ocaml/libref/Marshal.html.  
    *)

    val receive : ?timeout_duration:float -> 'a matcher list -> 'a option t 
    (** [receive timeout matchers] will wait for a message to be sent to this process which matches one of matchers provided in
        [matchers]. The first matching matcher in [matchers] will used process the matching message returning [Some result] where
        [result] is result of the matcher processing the matched message. All the other non-matching messages are left in the same
        order they came in.

        If a time out is provided and no matching messages has arrived in the time out period then None will be returned.

        If the [matchers] is empty then an [Empty_matchers] exception is raised.
    *)   

    val send : ProcessId.t -> message_type -> unit t
    (** [send process_id msg] will send, asynchronously, message [msg] to the process with id [process_id] (possibly running on a remote node).

        If [process_id] is resides on an unknown node then [InvalidNode] exception is raised.

        If [process_id] is an unknown process but the node on which it resides is known then send will still succeed (i.e., will not raise any exceptions).                       
    *)

    val broadcast : NodeId.t -> message_type -> unit t
    (** [broadcast node_id msg] will send, asynchronously, message [msg] to all the processes on [node_id]. 

        If [node_id] is an unknown node then [InvalidNode] exception is raised.           
    *) 

    val monitor : ProcessId.t -> monitor_ref t
    (** [monitor pid] will allows the calling process to monitor [pid]. When [pid] terminates (normally or abnormally) this monitoring
        process will receive a [termination_reason] message, which can be matched in [receive] using [termination_matcher].  

        If [process_id] is resides on an unknown node then [InvalidNode] exception is raised.          
    *)

    val unmonitor : monitor_ref -> unit t
    (** [unmonitor mref] will cause this process to stop monitoring the process which is referenced by [mref].
        If the current process is not monitoring the process referenced by [mref] then [unmonitor] is a no-op.            
    *) 

    val get_self_pid : ProcessId.t t
    (** [get_self_pid process] will return the process id associated with [process]. *)

    val get_self_node : NodeId.t t
    (** [get_self_node process] will return the node id associated with [process]. *)

    val get_remote_nodes : NodeId.t list t
    (** The list of all nodes currently active and inactive. *)

    val add_remote_node : string -> int -> string -> NodeId.t t
    (** [add_remote_node ip port name] will connect to the remote node at [ip]:[port] with name [name] and add it to the current nodes list of connected remote nodes.
        The newly added node id is returned as the result. 

        If the node is operating in local only mode then [Local_only_mode] is raised.
    *)

    val remove_remote_node : NodeId.t -> unit t
    (** [remove_remote_node node_id] will remove [node_id] from the list of connected remote nodes.

        If the node is operating in local only mode then [Local_only_mode] is raised. 
    *)

    val lift_io : 'a io -> 'a t
    (** [lift_io io] lifts the [io] computation into the process. *)

    val run_node : ?process:unit t -> node_config -> unit io
    (** [run_node process node_config] performs the necessary bootstrapping to start this node according to [node_config], 
        then, if provided, runs the initial [process] returning the resulting [io]).

        If it's called more than once then an exception of [Init_more_than_once] is raised. 
    *)
  end

  module Make (I : NonBlockIO) (M : Message_type) : (S with type message_type = M.t and type 'a io = 'a I.t and type logger = I.logger)
  (** Functor to create a [S]. *)

end
