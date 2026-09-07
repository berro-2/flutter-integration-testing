"""Bound a CI command and terminate its process group on timeout (POSIX)."""
import os
import signal
import subprocess
import sys

timeout = float(sys.argv[1])
process = subprocess.Popen(sys.argv[2:], start_new_session=True)
try:
    sys.exit(process.wait(timeout=timeout))
except subprocess.TimeoutExpired:
    os.killpg(process.pid, signal.SIGKILL)
    process.wait()
    print(f"Command timed out after {timeout:g} seconds.", file=sys.stderr)
    sys.exit(124)
