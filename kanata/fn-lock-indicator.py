#!/usr/bin/env python3
"""Keep a Lenovo IdeaPad's Fn-lock LED on while Kanata mouse mode is active."""

import json
import select
import socket
import time


HOST = "127.0.0.1"
PORT = 5829
MOUSE_LAYER = "mouse"
FN_LOCK = "/sys/bus/platform/devices/VPC2004:00/fn_lock"
POLL = 0.3


def read_fn_lock():
    try:
        with open(FN_LOCK) as file:
            return int(file.read().strip() or "0")
    except (OSError, ValueError):
        return 0


def write_fn_lock(value):
    try:
        with open(FN_LOCK, "w") as file:
            file.write("1" if value else "0")
    except OSError:
        pass


def run():
    decoder = json.JSONDecoder()
    mouse = False
    previous = False

    while True:
        try:
            with socket.create_connection((HOST, PORT), timeout=5) as sock:
                sock.sendall(b'{"RequestCurrentLayerName":{}}\n')
                buffer = ""

                while True:
                    ready, _, _ = select.select([sock], [], [], POLL)
                    if ready:
                        data = sock.recv(4096)
                        if not data:
                            break
                        buffer += data.decode("utf-8", "replace")

                        while buffer:
                            buffer = buffer.lstrip()
                            if not buffer:
                                break
                            try:
                                message, end = decoder.raw_decode(buffer)
                            except json.JSONDecodeError:
                                break
                            buffer = buffer[end:]

                            if "LayerChange" in message:
                                mouse = message["LayerChange"]["new"] == MOUSE_LAYER
                            elif "CurrentLayerName" in message:
                                mouse = message["CurrentLayerName"]["name"] == MOUSE_LAYER

                    if mouse:
                        if read_fn_lock() != 1:
                            write_fn_lock(1)
                    elif previous:
                        write_fn_lock(0)
                    previous = mouse
        except OSError:
            pass

        if previous:
            write_fn_lock(0)
        mouse = False
        previous = False
        time.sleep(2)


if __name__ == "__main__":
    run()
