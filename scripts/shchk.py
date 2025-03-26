#!/usr/bin/env python3

import sys
from argparse import ArgumentParser


def check(file: str) -> bool:
    eu: bool = False
    pipefail: bool = False

    lines: list[str] = open(file).readlines()
    for line in lines:
        if line.rstrip() == "set -eu":
            eu = True
        elif line.rstrip() == "set -o pipefail":
            pipefail = True

    if eu and pipefail:
        return True
    else:
        print(
            f"Error: {file}, 'set -eu': {eu}, 'set -o pipefail': {pipefail}",
            file=sys.stderr,
        )
        return False


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument("files")
    args = parser.parse_args()

    ok: bool = True
    for file in args.files:
        ok &= check(file)

    if ok:
        pass
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
