# distributed [![Build Status](https://travis-ci.org/essdotteedot/distributed.svg?branch=master)](https://travis-ci.org/essdotteedot/distributed)
Library to provide Erlang style distributed computations. This library is inspired by Cloud Haskell.

Primitive for spawning processes (in the Erlang sense) either remotely or locally, monitoring/unmonitoring spawned processes, sending, 
receiving, broadcasting messages to those processes. Unlike Erlang, the messages that are sent between processes are typed.

For more information see the Distributed.Process.S signature and the example in the examples directory.
