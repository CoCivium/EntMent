import json, os, re, glob
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # repo root
CONTENT = os.path.join(ROOT, "content")

def parse_frontmatter(text: str):
    # Very small YAML-ish parser for key: value and nested cometatrain lists.
    # Assumes frontmatter bounded by --- lines.
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return {}, text
    fm_raw, body = m.group(1), m.group(2)
    fm = {}
    stack = [fm]
    indent_stack = [0]
    key_stack = []

    def set_key(obj, k, v):
        obj[k] = v

    lines = fm_raw.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1; continue
        indent = len(line) - len(line.lstrip(" "))
        s = line.strip()

        # list item
        if s.startswith("- "):
            item = s[2:].strip().strip('"')
            # attach to last key on current object
            if not key_stack:
                i += 1; continue
            parent = stack[-1]
            k = key_stack[-1]
            if k not in parent or not isinstance(parent[k], list):
                parent[k] = []
            parent[k].append(item)
            i += 1; continue

        # key: value
        if ":" in s:
            k, v = s.split(":", 1)
            k = k.strip()
            v = v.strip()
            # adjust stack by indent
            while indent < indent_stack[-1] and len(stack) > 1:
                stack.pop(); indent_stack.pop()
                if key_stack: key_stack.pop()

            if v == "":
                # nested object
                cur = stack[-1]
                cur[k] = {}
                stack.append(cur[k])
                indent_stack.append(indent + 2)
                key_stack.append(k)
            else:
                v2 = v.strip().strip('"')
                # basic list inline not supported; keep scalar
                stack[-1][k] = v2
                # update last key for potential list items
                if key_stack:
                    key_stack[-1] = k
                else:
                    key_stack.append(k)
        i += 1

    return fm, body.strip()

items = []
for path in glob.glob(os.path.join(CONTENT, "**", "*.md"), recursive=True):
    with open(path, "r", encoding="utf-8") as f:
        txt = f.read()
    fm, body = parse_frontmatter(txt)
    rel = os.path.relpath(path, ROOT).replace("\\\\", "/").replace("\\", "/")
    items.append({
        "id": fm.get("id"),
        "type": fm.get("type"),
        "title": fm.get("title"),
        "status": fm.get("status"),
        "date_utc": fm.get("date_utc"),
        "tags": fm.get("tags"),
        "cometatrain": fm.get("cometatrain"),
        "path": rel,
        "body_markdown": body
    })

out = {
    "generated_utc": datetime.utcnow().strftime("%Y%m%dT%H%M%SZ"),
    "count": len(items),
    "items": sorted(items, key=lambda x: (x.get("type") or "", x.get("id") or ""))
}

out_path = os.path.join(ROOT, "api", "snapshots", "latest.json")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

print(f"Wrote {out_path} with {len(items)} items")
