#!/usr/bin/env python3
"""Open the browser demo in headless Chrome once per exit, and compare the exits.

The demo is one interface drawn two ways: the same frame goes onto a canvas and
into the document as elements, and it is written two ways, as calls and as a
tree. Each writing is opened twice, and the two screens of a pair must look the
same. That comparison needs no reference image and does
not care which fonts the machine has, which is what makes it a check a CI runner
can run: it compares the two ways of drawing against each other, not against a
picture taken on some other machine.

It also answers the questions a picture cannot: did anything throw, did the
page start at all, and is the canvas more than its background colour.

    python3 scripts/check_browser.py            # compare, exit non-zero on a difference
    python3 scripts/check_browser.py --keep DIR # keep the screenshots in DIR

Set MOONPANE_BROWSER to pick a browser; otherwise the usual names are tried.
"""

import argparse
import functools
import http.server
import os
import struct
import subprocess
import sys
import tempfile
import threading
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGE = "/hosts/pane/src/examples/browser/index.html"
WIDTH = 900
HEIGHT = 600
CELL = 8
BACKGROUND = (24, 24, 27)

# How much of a cell has to be drawn on for it to count as ink. A cell is 8 by 8
# pixels, smaller than a glyph, so a glyph that lands a pixel over moves ink out
# of a cell but not most of it; a shape in the wrong place empties whole cells.
INK = 60
MISPLACED = 0.5
MISPLACED_TOLERANCE = 0.0005
MEAN_TOLERANCE = 6.0
MIN_INK = 0.004
MIN_COLOURS = 16


class Failure(Exception):
    pass


def find_browser():
    named = os.environ.get("MOONPANE_BROWSER")
    if named:
        return named
    candidates = [
        "google-chrome-stable",
        "google-chrome",
        "chromium",
        "chromium-browser",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    ]
    for candidate in candidates:
        if os.path.isabs(candidate):
            if os.path.exists(candidate):
                return candidate
            continue
        for directory in os.environ.get("PATH", "").split(os.pathsep):
            path = os.path.join(directory, candidate)
            if os.path.exists(path):
                return path
    raise Failure(
        "no browser found; set MOONPANE_BROWSER to a Chrome or Edge executable"
    )


def serve():
    handler = functools.partial(
        http.server.SimpleHTTPRequestHandler, directory=ROOT
    )
    http.server.SimpleHTTPRequestHandler.log_message = lambda *args: None
    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    httpd.daemon_threads = True
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def run_page(browser, url, shot):
    """Load the page once, writing a screenshot and returning the DOM it ended on."""
    with tempfile.TemporaryDirectory() as profile:
        command = [
            browser,
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--no-first-run",
            "--disable-extensions",
            "--hide-scrollbars",
            "--no-proxy-server",
            "--proxy-bypass-list=*",
            "--force-device-scale-factor=1",
            f"--window-size={WIDTH},{HEIGHT}",
            f"--user-data-dir={profile}",
            # The demo draws in a requestAnimationFrame loop, so the clock has to
            # advance for anything to be drawn at all.
            "--virtual-time-budget=4000",
            f"--screenshot={shot}",
            "--dump-dom",
            url,
        ]
        done = subprocess.run(
            command, capture_output=True, text=True, timeout=120
        )
    dom = done.stdout
    if not dom.strip():
        raise Failure(
            f"{browser} printed no DOM for {url}\n{done.stderr.strip()[:2000]}"
        )
    return dom


MODES = (
    ("widgets-canvas", ""),
    ("widgets-html", "?html"),
    ("view-canvas", "?view"),
    ("view-html", "?view&html"),
)
WRITINGS = ("widgets", "view")

# What the document has to hold for each writing, so that a page which drew
# nothing but its background cannot pass on a blank screen.
WORDS = {
    "widgets": ("moonegui", "Press me", "Wrap the paragraph"),
    "view": ("moonegui", "Text size", "Ticked"),
}


def attr(dom, name):
    """The value of the data attribute the page leaves for this check."""
    marker = f'data-{name}="'
    at = dom.find(marker)
    if at < 0:
        return None
    at += len(marker)
    end = dom.find('"', at)
    return dom[at:end]


def read_png(path):
    """Width, height and rows of RGB triples, for the PNG Chrome writes."""
    with open(path, "rb") as handle:
        data = handle.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise Failure(f"{path} is not a PNG")
    at = 8
    header = None
    idat = bytearray()
    while at < len(data):
        length = struct.unpack(">I", data[at : at + 4])[0]
        kind = data[at + 4 : at + 8]
        body = data[at + 8 : at + 8 + length]
        at += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
    if header is None:
        raise Failure(f"{path} has no header")
    width, height, depth, colour, _, _, interlace = header
    if depth != 8 or interlace != 0 or colour not in (2, 6):
        raise Failure(
            f"{path} is not an 8 bit non-interlaced RGB image "
            f"(depth {depth}, colour {colour}, interlace {interlace})"
        )
    channels = 3 if colour == 2 else 4
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    rows = []
    previous = bytearray(stride)
    at = 0
    for _ in range(height):
        filter = raw[at]
        at += 1
        line = bytearray(raw[at : at + stride])
        at += stride
        if filter == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif filter == 2:
            for i in range(stride):
                line[i] = (line[i] + previous[i]) & 0xFF
        elif filter == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + previous[i]) >> 1)) & 0xFF
        elif filter == 4:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                up = previous[i]
                upleft = previous[i - channels] if i >= channels else 0
                guess = left + up - upleft
                da, db, dc = abs(guess - left), abs(guess - up), abs(guess - upleft)
                near = left if da <= db and da <= dc else (up if db <= dc else upleft)
                line[i] = (line[i] + near) & 0xFF
        elif filter != 0:
            raise Failure(f"{path} uses filter {filter}")
        rows.append(
            [
                (line[i], line[i + 1], line[i + 2])
                for i in range(0, stride, channels)
            ]
        )
        previous = line
    return width, height, rows


def luminance(pixel):
    r, g, b = pixel
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def patches(rows):
    """The page as a grid of how much of each cell is drawn on."""
    grid = []
    for top in range(0, HEIGHT, CELL):
        line = []
        for left in range(0, WIDTH, CELL):
            drawn = 0
            for y in range(top, min(top + CELL, HEIGHT)):
                row = rows[y]
                for x in range(left, min(left + CELL, WIDTH)):
                    if luminance(row[x]) > INK:
                        drawn += 1
            line.append(drawn / (CELL * CELL))
        grid.append(line)
    return grid


def ink(rows):
    """How much of the page is not the background, and how many colours there are."""
    background = luminance(BACKGROUND)
    drawn = 0
    colours = set()
    for row in rows:
        for pixel in row:
            colours.add(pixel)
            if abs(luminance(pixel) - background) > 6:
                drawn += 1
    return drawn / (WIDTH * HEIGHT), len(colours)


def compare(left, right):
    """Mean difference in how much of a cell is drawn on, and the share of cells
    that differ by more than half of themselves."""
    total = 0.0
    cells = 0
    moved = 0
    for ly, ry in zip(left, right):
        for a, b in zip(ly, ry):
            total += abs(a - b)
            cells += 1
            if abs(a - b) > MISPLACED:
                moved += 1
    return total / cells, moved / cells


def sketch(grid):
    """The page as a picture of blocks, so a failure says where to look."""
    ramp = " .:-=+*#%@"
    out = []
    for line in grid:
        out.append("".join(ramp[min(len(ramp) - 1, int(value * 10))] for value in line))
    return "\n".join(out)


def check(browser, keep):
    httpd = serve()
    host, port = httpd.server_address[:2]
    base = f"http://{host}:{port}{PAGE}"
    shots = keep or tempfile.mkdtemp(prefix="moonpane-browser-")
    os.makedirs(shots, exist_ok=True)
    problems = []
    try:
        report = {}
        for name, query in MODES:
            shot = os.path.join(shots, f"{name}.png")
            dom = run_page(browser, base + query, shot)
            error = attr(dom, "error")
            backend = attr(dom, "backend")
            if error:
                problems.append(f"{name}: the page threw {error!r}")
            if backend != name:
                problems.append(
                    f"{name}: the page says it is drawing with {backend!r}"
                )
            writing, exit = name.split("-")
            if exit == "html":
                for word in WORDS[writing]:
                    if word not in dom:
                        problems.append(f"{name}: {word!r} is not in the document")
                elements = dom.count("position: absolute")
                if elements < 12:
                    problems.append(
                        f"{name}: only {elements} positioned elements were drawn"
                    )
                report[name + "-elements"] = elements
            width, height, rows = read_png(shot)
            if (width, height) != (WIDTH, HEIGHT):
                problems.append(
                    f"{name}: the screenshot is {width} by {height}, not "
                    f"{WIDTH} by {HEIGHT}"
                )
            drawn, colours = ink(rows)
            if drawn < MIN_INK:
                problems.append(f"{name}: only {drawn:.3%} of the page is drawn on")
            if colours < MIN_COLOURS:
                problems.append(f"{name}: the page has {colours} colours")
            report[name] = (drawn, colours, patches(rows))
        print(f"browser      {browser}")
        for writing in WRITINGS:
            canvas_ink, canvas_colours, canvas_grid = report[writing + "-canvas"]
            html_ink, html_colours, html_grid = report[writing + "-html"]
            mean, moved = compare(canvas_grid, html_grid)
            if mean > MEAN_TOLERANCE or moved > MISPLACED_TOLERANCE:
                problems.append(
                    f"{writing}: the canvas and the document disagree: mean "
                    f"{mean:.2f}, {moved:.2%} of cells are drawn on differently"
                    + "\n"
                    + sketch(canvas_grid)
                    + "\n"
                    + sketch(html_grid)
                )
            print(
                f"{writing:8} canvas {canvas_ink:.2%} drawn, "
                f"{canvas_colours} colours; document {html_ink:.2%} drawn, "
                f"{html_colours} colours, "
                f"{report[writing + '-html-elements']} elements"
            )
            print(
                f"{'':8} {moved:.3%} of cells drawn on differently, mean "
                f"{mean:.3f} of one"
            )
        print(f"screenshots  {shots}")
    finally:
        httpd.shutdown()
    if problems:
        raise Failure("\n".join(problems))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--keep", metavar="DIR", help="write the screenshots here and keep them"
    )
    options = parser.parse_args()
    try:
        check(find_browser(), options.keep)
    except Failure as failure:
        print(f"failed: {failure}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
