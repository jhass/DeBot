# CeBot

CeBot is an IRC bot written in [Crystal](http://crystal-lang.org).

Currently this repository contains not only the bot but also the underlying
libraries and tools until they are mature enough to be extracted into their
own projects.


## irc

Base library that handles establishing and maintaining an connection to
an IRC network, message de-/serialization and calling handlers for
received messages.

### Dependencies

* Crystal
* thread
* core_ext

## framework

Abstraction layer to provide an easy to use API and commonly used tools
for developing IRC bots.

### Dependencies

* Crystal
* irc
* thread
* core_ext

## bot

The actual bot, consisting of plugins and a file to actually instantiate
the bot.

### Dependencies

* Crystal
* framework
* core_ext
* sandbox (if crystal_eval plugin is activated)

## core_ext

A collection of monkey patches to stdlib classes that might or might not
be upstreamed into Crystal

### Dependencies

* Crystal

## thread

A collection of threading primitives such as a Queue and a ReadWriteLock

### Dependencies

* Crystal
