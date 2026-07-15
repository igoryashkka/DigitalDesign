#!/usr/bin/env python3
"""
Live screen capture -> resize to 320x240 -> send RGB565 stripes over UART.

Protocol per packet :
  SOF: 0x55 0xAA 0x5A 0xA5
  Y start: 2 bytes (hi bit in bit0 of first byte, then low byte)
  Pixel payload: width * stripe_h pixels, RGB565 big-endian per pixel
"""

from __future__ import annotations

import argparse
import sys
import threading
import time
from dataclasses import dataclass

try:
    import serial
except ImportError:
    print("Missing dependency: pyserial")
    print("Install with: pip install pyserial mss pillow")
    sys.exit(1)

try:
    import mss
except ImportError:
    print("Missing dependency: mss")
    print("Install with: pip install pyserial mss pillow")
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("Missing dependency: pillow")
    print("Install with: pip install pyserial mss pillow")
    sys.exit(1)


SOF = bytes((0x55, 0xAA, 0x5A, 0xA5))


@dataclass
class Config:
    port: str
    baud: int
    width: int
    height: int
    stripe_h: int
    send_hz: float
    capture_hz: float
    monitor: int


def parse_args() -> Config:
    p = argparse.ArgumentParser(description="Stream screen to ST7789 over UART")
    p.add_argument("--port", default="COM12", help="COM port (default: COM12)")
    p.add_argument("--baud", type=int, default=2_000_000, help="UART baud rate")
    p.add_argument("--width", type=int, default=320, help="Target frame width")
    p.add_argument("--height", type=int, default=240, help="Target frame height")
    p.add_argument("--stripe-h", type=int, default=4, help="Stripe height in lines")
    p.add_argument("--send-hz", type=float, default=30.0, help="Stripe packets per second")
    p.add_argument("--capture-hz", type=float, default=6.0, help="Screen capture FPS")
    p.add_argument(
        "--monitor",
        type=int,
        default=1,
        help="Monitor index for mss (1 = primary monitor)",
    )
    a = p.parse_args()

    if a.width <= 0 or a.height <= 0:
        raise SystemExit("width/height must be > 0")
    if a.stripe_h <= 0 or a.stripe_h > a.height:
        raise SystemExit("stripe-h must be in range [1, height]")
    if a.send_hz <= 0:
        raise SystemExit("send-hz must be > 0")
    if a.capture_hz <= 0:
        raise SystemExit("capture-hz must be > 0")
    if a.monitor < 1:
        raise SystemExit("monitor index must be >= 1")

    return Config(
        port=a.port,
        baud=a.baud,
        width=a.width,
        height=a.height,
        stripe_h=a.stripe_h,
        send_hz=a.send_hz,
        capture_hz=a.capture_hz,
        monitor=a.monitor,
    )


def rgb888_to_rgb565_be(rgb_bytes: bytes) -> bytes:
    out = bytearray((len(rgb_bytes) // 3) * 2)
    o = 0
    for i in range(0, len(rgb_bytes), 3):
        r = rgb_bytes[i]
        g = rgb_bytes[i + 1]
        b = rgb_bytes[i + 2]
        v = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
        out[o] = (v >> 8) & 0xFF
        out[o + 1] = v & 0xFF
        o += 2
    return bytes(out)


def make_packet(y_start: int, stripe_rgb565_be: bytes) -> bytes:
    y_hi = (y_start >> 8) & 0x01
    y_lo = y_start & 0xFF
    return SOF + bytes((y_hi, y_lo)) + stripe_rgb565_be


def capture_frame_rgb565(sct: mss.MSS, mon: dict, cfg: Config) -> bytes:
    shot = sct.grab(mon)
    img = Image.frombytes("RGB", shot.size, shot.rgb)
    frame = img.resize((cfg.width, cfg.height), Image.Resampling.BILINEAR)
    return rgb888_to_rgb565_be(frame.tobytes())


def capture_worker(cfg: Config, shared: dict, lock: threading.Lock, stop_evt: threading.Event) -> None:
    period = 1.0 / cfg.capture_hz
    next_t = time.perf_counter()

    try:
        with mss.MSS() as sct:
            if cfg.monitor >= len(sct.monitors):
                with lock:
                    shared["error"] = (
                        f"monitor index {cfg.monitor} not found; available 1..{len(sct.monitors)-1}"
                    )
                return

            mon = sct.monitors[cfg.monitor]
            with lock:
                shared["monitor_info"] = (
                    f"Capture monitor {cfg.monitor}: {mon['width']}x{mon['height']} -> "
                    f"{cfg.width}x{cfg.height}, stripe={cfg.stripe_h}, send_hz={cfg.send_hz}, capture_hz={cfg.capture_hz}"
                )

            while not stop_evt.is_set():
                frame565 = capture_frame_rgb565(sct, mon, cfg)
                with lock:
                    shared["frame565"] = frame565
                    shared["capture_count"] += 1

                next_t += period
                sleep_t = next_t - time.perf_counter()
                if sleep_t > 0:
                    stop_evt.wait(sleep_t)
                else:
                    next_t = time.perf_counter()
    except Exception as e:  # noqa: BLE001
        with lock:
            shared["error"] = f"capture thread error: {e}"


def main() -> int:
    cfg = parse_args()

    print(f"Open {cfg.port} @ {cfg.baud}...")
    ser = serial.Serial(cfg.port, cfg.baud, timeout=0)

    y = 0
    send_period = 1.0 / cfg.send_hz
    capture_period = 1.0 / cfg.capture_hz
    next_send_t = time.perf_counter()
    next_capture_t = next_send_t

    shared = {
        "frame565": None,
        "capture_count": 0,
        "monitor_info": None,
        "error": None,
    }
    lock = threading.Lock()
    stop_evt = threading.Event()
    th = threading.Thread(target=capture_worker, args=(cfg, shared, lock, stop_evt), daemon=True)
    th.start()

    sent_packets = 0
    prev_capture_count = 0
    stats_t0 = time.perf_counter()

    try:
        stripe_payload_bytes = cfg.width * cfg.stripe_h * 2

        # Wait for first captured frame.
        while True:
            with lock:
                err = shared["error"]
                info = shared["monitor_info"]
                frame565 = shared["frame565"]
            if err:
                raise SystemExit(err)
            if info:
                print(info)
                break
            time.sleep(0.01)

        while frame565 is None:
            with lock:
                err = shared["error"]
                frame565 = shared["frame565"]
            if err:
                raise SystemExit(err)
            time.sleep(0.005)

        while True:
            with lock:
                err = shared["error"]
                frame565 = shared["frame565"]
                capture_count = shared["capture_count"]
            if err:
                raise SystemExit(err)

            start = y * cfg.width * 2
            end = start + stripe_payload_bytes
            payload = frame565[start:end]
            packet = make_packet(y, payload)
            ser.write(packet)

            y += cfg.stripe_h
            if y >= cfg.height:
                y = 0

            sent_packets += 1
            now = time.perf_counter()
            if now - stats_t0 >= 1.0:
                pps = sent_packets / (now - stats_t0)
                full_fps = pps * (cfg.stripe_h / cfg.height)
                cps = (capture_count - prev_capture_count) / (now - stats_t0)
                print(f"packets/s={pps:5.2f}  capture/s={cps:5.2f}  est_full_fps={full_fps:5.2f}")
                sent_packets = 0
                prev_capture_count = capture_count
                stats_t0 = now

            next_send_t += send_period
            sleep_t = next_send_t - time.perf_counter()
            if sleep_t > 0:
                time.sleep(sleep_t)
            else:
                next_send_t = time.perf_counter()

    except KeyboardInterrupt:
        print("\nStopped by user")
    finally:
        stop_evt.set()
        th.join(timeout=1.0)
        ser.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
