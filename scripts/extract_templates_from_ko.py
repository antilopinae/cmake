#!/usr/bin/env python3
import sys
import re


def build_pattern(names):
    """
    names: ["hhh", "vec", ...]
    превращает в regex: (hhh|vec)<([^>]+)>
    """
    return re.compile(
        rb"(" + b"|".join(name.encode() for name in names) + rb")<([^>]+)>"
    )


def transform(name: bytes, params: bytes) -> bytes:
    """hhh<int, true> → hhh_int_true_ с заменой всех пробелов на _"""
    parts = [p.replace(b" ", b"_") for p in params.split(b",")]
    return name + b"_" + b"_".join(parts) + b"_"


def patch_binary(data: bytearray, pattern) -> int:
    matches = list(pattern.finditer(data))
    matches.reverse()

    patched = 0
    for m in matches:
        start, end = m.span()
        name = m.group(1)
        params = m.group(2)

        replacement = transform(name, params)

        data[start:end] = replacement
        patched += 1

    return patched


def main():
    if len(sys.argv) < 3:
        print("Usage: patch_templates.py <file> <name1> <name2> ...")
        print("Example: patch_templates.py module.ko hhh vec map")
        return

    path = sys.argv[1]
    names = sys.argv[2:]

    if len(names) == 1:
        names = names[0].split()

    names = sorted(names, key=len, reverse=True)
    print("Names received:", ", ".join(names))

    pattern = build_pattern(names)

    with open(path, "rb") as f:
        data = bytearray(f.read())

    count = patch_binary(data, pattern)

    out = path + ".patched"
    with open(out, "wb") as f:
        f.write(data)

    print(f"Patched {count} occurrences")
    print(f"Output: {out}")


if __name__ == "__main__":
    main()
