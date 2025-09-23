#!/usr/bin/env python3
import sys
import time
import random
import argparse

try:
    import serial  # pyserial
except ImportError:
    print("This tool requires pyserial. Install with: pip install pyserial", file=sys.stderr)
    raise

EOL_MAP = {
    "lf": "\n",
    "crlf": "\r\n",
}

def format_cmd(op: int, a: int, b: int, eol: str) -> bytes:
    if not (0 <= op <= 5):
        raise ValueError("op must be 0..5 (0=ADD,1=SUB,2=MUL,3=SHL,4=SHR,5=SAR)")
    if not (-128 <= a <= 127 and -128 <= b <= 127):
        raise ValueError("A and B must be -128..127")
    cmd = f"alu:{op}:{a};{b}{eol}"
    return cmd.encode("ascii")

def open_port(port: str, baud: int, timeout: float):
    ser = serial.Serial(
        port=port,
        baudrate=baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=timeout,
        write_timeout=timeout,
    )
    # Clean any stale bytes
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    return ser

def read_exact(ser, n: int, timeout: float) -> bytes:
    """Read exactly n bytes or return what we got before timeout."""
    deadline = time.time() + timeout
    buf = bytearray()
    while len(buf) < n and time.time() < deadline:
        chunk = ser.read(n - len(buf))
        if chunk:
            buf.extend(chunk)
        else:
            time.sleep(0.001)
    return bytes(buf)

def run_interactive(ser, eol: str):
    print("Interactive mode. Type commands as:")
    print("  op a b")
    print("Where op=0..5, a=0..255, b=0..255. Example: 0 12 34  (means: alu:0:12;34)")
    print("You can also paste a full 'alu:...' line. Ctrl+C to exit.\n")
    while True:
        try:
            line = input("alu> ").strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) == 1 and parts[0].startswith("alu:"):
                raw = parts[0]
                if not (raw.endswith("\n") or raw.endswith("\r") or raw.endswith("\r\n")):
                    raw += eol
                tx = raw.encode("ascii")
            else:
                if len(parts) != 3:
                    print("Enter exactly 3 numbers: op a b  OR a raw 'alu:...' command.")
                    continue
                op, a, b = map(int, parts)
                tx = format_cmd(op, a, b, eol)

            ser.write(tx); ser.flush()
            rx = read_exact(ser, len(tx), ser.timeout or 1.0)
            print(f"TX ({len(tx)}): {tx!r}")
            print(f"RX ({len(rx)}): {rx!r}")
            if rx != tx:
                print("WARNING: echo mismatch! (Check baud/line settings and ground.)")
        except KeyboardInterrupt:
            print("\nBye.")
            break
        except Exception as e:
            print(f"Error: {e}")

def run_selftest(ser, eol: str, rounds: int = 50, seed: int = 1):
    rng = random.Random(seed)
    print(f"Running selftest: {rounds} random commands...")
    ok, bad = 0, 0
    for i in range(rounds):
        op = rng.randint(0, 5)   # use 0..2 since SHL/SHR/SAR may be disabled
        a  = rng.randint(-128, 127)
        b  = rng.randint(-128, 127)
        tx = format_cmd(op, a, b, eol)
        ser.write(tx); ser.flush()
        rx = read_exact(ser, len(tx), ser.timeout or 1.0)
        match = (rx == tx)
        if match:
            ok += 1
        else:
            bad += 1
        print(f"[{i:02d}] TX={tx!r} RX={rx!r}  {'OK' if match else 'MISMATCH'}")
    print(f"Selftest done. OK={ok}, MISMATCH={bad}")

def main():
    ap = argparse.ArgumentParser(description="UART CLI for alu:<op>:<A>;<B> protocol (echo-check)")
    ap.add_argument("--port", "-p", required=True, help="Serial port (e.g., COM5 or /dev/ttyUSB0)")
    ap.add_argument("--baud", "-b", type=int, default=115200, help="Baud rate (default: 115200)")
    ap.add_argument("--timeout", "-t", type=float, default=0.5, help="I/O timeout seconds (default: 0.5)")
    ap.add_argument("--eol", choices=EOL_MAP.keys(), default="lf", help="Line ending: lf or crlf (default: lf)")
    ap.add_argument("--selftest", action="store_true", help="Run random command self-test (echo only) and exit")
    ap.add_argument("--rounds", type=int, default=50, help="Number of self-test rounds (default: 50)")
    ap.add_argument("--seed", type=int, default=1, help="Random seed for self-test (default: 1)")
    args = ap.parse_args()

    eol = EOL_MAP[args.eol]
    with open_port(args.port, args.baud, args.timeout) as ser:
        print(f"Opened {ser.port} @ {ser.baudrate} 8N1, timeout={ser.timeout}")
        print("Note: this script expects the FPGA to echo bytes (RX->TX loopback in your top_alu).")
        if args.selftest:
            run_selftest(ser, eol, args.rounds, args.seed)
        else:
            run_interactive(ser, eol)

if __name__ == "__main__":
    main()
