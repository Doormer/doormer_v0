"""Run with python3 test/site/demo_layout_browser_test.py; requires Chrome.

Set CHROME_BIN if Chrome is not installed at its standard macOS location.
Checks expanded diagrams and navigation without automatic page scrolling at
five sizes with and without reduced motion.
"""

from functools import partial
from html.parser import HTMLParser
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from threading import Thread
import unittest


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "test/site/fixtures/demo_layout.html"


class TestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/__demo_layout_test":
            body = FIXTURE.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(body)
        else:
            super().do_GET()

    def log_message(self, format, *args):
        pass


class ResultParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.result = ""

    def handle_starttag(self, tag, attrs):
        if tag == "pre" and ("id", "results") in attrs:
            self.active = True

    def handle_endtag(self, tag):
        if tag == "pre":
            self.active = False

    def handle_data(self, data):
        if self.active:
            self.result += data


class DemoLayoutTest(unittest.TestCase):
    def test_diagrams_expand_and_navigation_does_not_scroll_to_top(self):
        chrome = (
            os.environ.get("CHROME_BIN")
            or shutil.which("google-chrome")
            or shutil.which("chromium")
            or "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        )
        self.assertTrue(Path(chrome).is_file(), "Set CHROME_BIN to a Chrome executable")
        handler = partial(TestHandler, directory=str(ROOT / "web"))
        server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            for motion in ("reduce", "no-preference"):
                with self.subTest(motion=motion):
                    with tempfile.TemporaryDirectory(prefix="doormer-layout-") as profile:
                        run = subprocess.run(
                            [
                                chrome,
                                "--headless",
                                "--no-first-run",
                                "--no-default-browser-check",
                                f"--force-prefers-reduced-motion={motion}",
                                f"--user-data-dir={profile}",
                                "--window-size=1440,1000",
                                "--virtual-time-budget=30000",
                                "--dump-dom",
                                f"http://127.0.0.1:{server.server_port}/__demo_layout_test",
                            ],
                            capture_output=True,
                            text=True,
                            timeout=60,
                            check=True,
                        )
                    parser = ResultParser()
                    parser.feed(run.stdout)
                    self.assertNotEqual(parser.result, "Running", "Browser test did not finish")
                    result = json.loads(parser.result)
                    self.assertNotIn("error", result, result.get("error"))
                    self.assertTrue(result["pass"], "\n".join(result["failures"]))
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == "__main__":
    unittest.main()
