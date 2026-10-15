"""Test-only lifetime for thread-affine Tcl/Tk cyclic finalizers."""

from contextlib import contextmanager
import gc
import threading


@contextmanager
def tk_main_thread_lifetime():
    """Suppress automatic collection, not assertions, during a GUI class.

    Source inventory helpers can start threads while a destroyed window still
    has Python cycles. An allocation in such a thread must not finalize Tcl
    objects. unittest closes this context after the class's ordinary cleanups;
    explicit collection then runs synchronously on its original main thread.
    This does not intercept explicit collections made by other code.
    """
    if threading.current_thread() is not threading.main_thread():
        raise RuntimeError("real Tk tests require the process main thread")
    enabled = gc.isenabled()
    gc.disable()
    try:
        yield
    finally:
        try:
            gc.collect()
        finally:
            if enabled:
                gc.enable()
            else:
                gc.disable()
