"""Web-build check helper (9 Nov 2026): a minimal Chrome DevTools Protocol client, standard
library only, used to measure the Web export in headless Chrome (record in
docs/guides/FINAL_VERIFICATION.md "Web build of the day-night cycle"). Steps used:
  godot --headless --path . --export-release "Web" <scratch>/web/index.html
  (cd <scratch>/web && python3 -m http.server 8765 --bind 127.0.0.1)
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --remote-debugging-port=9333
      --user-data-dir=<scratch>/chrome-profile --window-size=1280,800 --force-device-scale-factor=2
      --enable-gpu --ignore-gpu-blocklist --disable-gpu-vsync --disable-frame-rate-limit about:blank
  python3 web_measure.py nav http://localhost:8765/index.html ; python3 web_measure.py logs 30
Usage: web_measure.py eval JS | click X Y | wheel X Y DY | key KEY | shot PATH | nav URL | logs SECONDS
(X, Y in CSS pixels.) Connects to the first page target on 127.0.0.1:9333. Writes files only
for `shot`."""
import base64, json, os, socket, struct, sys, time, urllib.request

PORT = 9333


def page_ws():
    targets = json.load(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json"))
    page = [t for t in targets if t.get("type") == "page"][0]
    return page["webSocketDebuggerUrl"]


class WS:
    def __init__(self, url):
        rest = url.split("://", 1)[1]
        hostport, path = rest.split("/", 1)
        host, port = hostport.split(":")
        self.s = socket.create_connection((host, int(port)))
        key = base64.b64encode(os.urandom(16)).decode()
        self.s.sendall((f"GET /{path} HTTP/1.1\r\nHost: {hostport}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                        f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        buf = b""
        while b"\r\n\r\n" not in buf:
            buf += self.s.recv(4096)
        self.extra = buf.split(b"\r\n\r\n", 1)[1]
        self.next_id = 0

    def _recv_exact(self, n):
        while len(self.extra) < n:
            chunk = self.s.recv(1 << 20)
            if not chunk:
                raise EOFError
            self.extra += chunk
        out, self.extra = self.extra[:n], self.extra[n:]
        return out

    def send(self, obj):
        data = json.dumps(obj).encode()
        header = bytearray([0x81])
        n = len(data)
        if n < 126:
            header.append(0x80 | n)
        elif n < 65536:
            header.append(0x80 | 126); header += struct.pack(">H", n)
        else:
            header.append(0x80 | 127); header += struct.pack(">Q", n)
        mask = os.urandom(4)
        header += mask
        self.s.sendall(bytes(header) + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def recv(self):
        message = b""
        while True:
            b0, b1 = self._recv_exact(2)
            n = b1 & 0x7F
            if n == 126:
                n = struct.unpack(">H", self._recv_exact(2))[0]
            elif n == 127:
                n = struct.unpack(">Q", self._recv_exact(8))[0]
            payload = self._recv_exact(n)
            if b0 & 0x0F in (1, 0):
                message += payload
                if b0 & 0x80:
                    return json.loads(message)

    def call(self, method, params=None, timeout=120):
        self.next_id += 1
        my_id = self.next_id
        self.send({"id": my_id, "method": method, "params": params or {}})
        self.s.settimeout(timeout)
        while True:
            msg = self.recv()
            if msg.get("id") == my_id:
                if "error" in msg:
                    raise RuntimeError(msg["error"])
                return msg.get("result", {})


def main():
    ws = WS(page_ws())
    cmd = sys.argv[1]
    if cmd == "eval":
        r = ws.call("Runtime.evaluate", {"expression": sys.argv[2], "awaitPromise": True, "returnByValue": True}, timeout=300)
        print(json.dumps(r.get("result", {}).get("value", r), indent=1))
    elif cmd == "nav":
        ws.call("Page.navigate", {"url": sys.argv[2]})
    elif cmd == "click":
        x, y = float(sys.argv[2]), float(sys.argv[3])
        for t in ("mouseMoved", "mousePressed", "mouseReleased"):
            ws.call("Input.dispatchMouseEvent", {"type": t, "x": x, "y": y, "button": "left", "clickCount": 1})
            time.sleep(0.08)
    elif cmd == "wheel":
        x, y, dy = float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
        ws.call("Input.dispatchMouseEvent", {"type": "mouseWheel", "x": x, "y": y, "deltaX": 0, "deltaY": dy})
    elif cmd == "key":
        key = sys.argv[2]
        codes = {"F3": 114, "Escape": 27}
        for t in ("rawKeyDown", "keyUp"):
            ws.call("Input.dispatchKeyEvent", {"type": t, "key": key, "code": key, "windowsVirtualKeyCode": codes.get(key, 0)})
    elif cmd == "shot":
        r = ws.call("Page.captureScreenshot", {"format": "png"})
        open(sys.argv[2], "wb").write(base64.b64decode(r["data"]))
        print("saved", sys.argv[2])
    elif cmd == "logs":
        ws.call("Runtime.enable")
        end = time.time() + float(sys.argv[2])
        ws.s.settimeout(1)
        while time.time() < end:
            try:
                msg = ws.recv()
            except (socket.timeout, TimeoutError):
                continue
            if msg.get("method") == "Runtime.consoleAPICalled":
                print(" ".join(str(a.get("value", a.get("description", ""))) for a in msg["params"]["args"]))


if __name__ == "__main__":
    main()
