#                Chronos Test Suite
#            (c) Copyright 2018-Present
#         Status Research & Development GmbH
#
#              Licensed under either of
#  Apache License, version 2.0, (LICENSE-APACHEv2)
#              MIT license (LICENSE-MIT)
import unittest2
import ../chronos

{.used.}

when not defined(windows):
  import posix

suite "Signal handling test suite":
  when not defined(windows):
    var
      signalCounter = 0
      sigfd = -1

    proc signalProc(udata: pointer) =
      signalCounter = cast[int](udata)
      try:
        removeSignal(sigfd)
      except Exception as exc:
        raiseAssert exc.msg

    proc asyncProc() {.async.} =
      await sleepAsync(500.milliseconds)

    proc test(signal, value: int): bool =
      try:
        sigfd = addSignal(signal, signalProc, cast[pointer](value))
      except Exception as exc:
        raiseAssert exc.msg
      var fut = asyncProc()
      discard posix.kill(posix.getpid(), cint(signal))
      waitFor(fut)
      signalCounter == value

    proc testWait(signal: int): bool =
      var fut = waitSignal(signal)
      discard posix.kill(posix.getpid(), cint(signal))
      waitFor(fut)
      true

  test "SIGINT test":
    when not defined(windows):
      check test(SIGINT, 31337) == true
    else:
      skip()

  test "SIGTERM test":
    when defined(windows):
      skip()
    else:
      check test(SIGTERM, 65537) == true

  test "waitSignal(SIGINT) test":
    when defined(windows):
      skip()
    else:
      check testWait(SIGINT) == true

  test "waitSignal(SIGTERM) test":
    when defined(windows):
      skip()
    else:
      check testWait(SIGTERM) == true
