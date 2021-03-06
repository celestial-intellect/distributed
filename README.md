# distributed [![Build Status](https://travis-ci.org/essdotteedot/distributed.svg?branch=master)](https://travis-ci.org/essdotteedot/distributed) [![Coverage Status](https://coveralls.io/repos/github/essdotteedot/distributed/badge.svg?branch=master)](https://coveralls.io/github/essdotteedot/distributed?branch=master) [![Docs Online](https://img.shields.io/badge/Docs-Online-brightgreen.svg)](https://essdotteedot.github.io/distributed/)
Library to provide Erlang style distributed computations. This library is inspired by Cloud Haskell.

Primitives for spawning processes (in the Erlang sense) either remotely or locally, monitoring/unmonitoring spawned processes, sending, 
receiving, broadcasting messages to those processes. Unlike Erlang, the messages that are sent between processes are typed.

Installation
------------

The library is available via [OPAM](https://opam.ocaml.org):

    $ opam install distributed

Documentation
-------------

The API documentation is available [here](https://essdotteedot.github.io/distributed/).
Example programs can be found in the [examples] (examples) directory.

License
-------

[MIT License](LICENSE)
