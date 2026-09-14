#!/usr/bin/env python3
"""Check Pages assets, fragment links, and repository artifact links."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "docs/site"
REPOSITORY = "/CloudSec-Jay/cloud-ops-engineering/"
errors = []


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.path = path
        self.ids = set()
        self.links = []
        self.has_title = False
        self.has_main = False
        self.feed(path.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if "id" in attrs:
            if attrs["id"] in self.ids:
                errors.append(f"{self.path.name}: duplicate id {attrs['id']}")
            self.ids.add(attrs["id"])
        self.has_title |= tag == "title"
        self.has_main |= tag == "main"
        for key in ("href", "src"):
            if key in attrs:
                self.links.append(attrs[key])
        if tag == "script" or any(key.startswith("on") for key in attrs):
            errors.append(f"{self.path.name}: scripts are disabled by site CSP")


pages = {path.resolve(): Page(path) for path in SITE.glob("*.html")}
if not pages or not (SITE / "index.html").is_file():
    errors.append("Site must contain index.html")
for path in SITE.rglob("*"):
    if path.is_symlink():
        errors.append(f"Symlinks must not be published: {path}")
    if path.is_file() and path.suffix not in (".html", ".css") and path.name != ".nojekyll":
        errors.append(f"Unexpected public asset: {path}")
for path, page in pages.items():
    if not page.has_title or not page.has_main:
        errors.append(f"{path.name}: missing title or main landmark")
    for value in page.links:
        url = urlsplit(value)
        if url.scheme or url.netloc:
            if url.scheme != "https":
                errors.append(f"{path.name}: unexpected link scheme: {value}")
            if url.netloc == "github.com" and url.path.startswith(REPOSITORY):
                suffix = url.path[len(REPOSITORY):]
                if suffix.startswith(("blob/main/", "tree/main/")):
                    target = ROOT / unquote(suffix.split("/", 2)[2])
                    if not target.exists():
                        errors.append(f"{path.name}: missing repository artifact: {value}")
            continue
        target = (path.parent / unquote(url.path)).resolve() if url.path else path
        if not target.is_relative_to(SITE.resolve()) or not target.is_file():
            errors.append(f"{path.name}: invalid local asset: {value}")
        elif url.fragment and (target not in pages or unquote(url.fragment) not in pages[target].ids):
            errors.append(f"{path.name}: missing fragment: {value}")
if errors:
    raise SystemExit("\n".join(errors))
print(f"Validated {len(pages)} pages: local assets, fragments, and repository paths.")
