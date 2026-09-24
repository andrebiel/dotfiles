#!/usr/bin/env python3

import errno
import os
import pty
import select
import signal
import sys
import time


def main() -> int:
    command, keys = sys.argv[1:3]
    child_pid, terminal = pty.fork()
    if child_pid == 0:
        os.execvpe(command, [command, "show"], os.environ)

    output = b""
    sent = 0
    deadline = time.monotonic() + 8
    status = None
    while time.monotonic() < deadline:
        ready, _, _ = select.select([terminal], [], [], 0.1)
        if ready:
            try:
                output += os.read(terminal, 65_536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise

        dashboard_draws = output.count(b"AI USAGE")
        if sent < len(keys) and dashboard_draws >= sent + 2:
            os.write(terminal, keys[sent].encode())
            sent += 1

        finished, status = os.waitpid(child_pid, os.WNOHANG)
        if finished:
            return os.waitstatus_to_exitcode(status)

    os.kill(child_pid, signal.SIGTERM)
    os.waitpid(child_pid, 0)
    sys.stderr.write("PTY child did not exit after the requested keys\n")
    return 124


if __name__ == "__main__":
    raise SystemExit(main())
