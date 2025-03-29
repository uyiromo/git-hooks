#!/usr/bin/env python3

import json
import sys
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class Gitmoji:
    emoji: str
    entity: str
    code: str
    description: str
    name: str
    semver: Optional[str]


def main(allowable: list[str], commit_msg: Path) -> None:

    # Load the Gitmoji JSON data
    gitmojis = [Gitmoji(**gitmoji) for gitmoji in json.load(open("/etc/gitmojis.json"))["gitmojis"]]

    # only allowable gitmojis
    gitmojis = list(filter(lambda x: (x.code in allowable) or (x.emoji in allowable), gitmojis))

    # Check if the commit message starts with a Gitmoji
    msg: str = commit_msg.read_text()
    err: bool = True
    for gitmoji in gitmojis:
        startswith_emoji = msg.startswith(gitmoji.emoji)
        startswith_code = msg.startswith(gitmoji.code)
        if startswith_emoji or startswith_code:
            err = False
            break

    if err:
        print("Commit message must start with a Gitmoji", file=sys.stderr)
        print("Allowable gitmojis: ", file=sys.stderr)
        for gitmoji in gitmojis:
            print(f"- {gitmoji.emoji}: {gitmoji.code}: {gitmoji.description}", file=sys.stderr)

        sys.exit(1)


if __name__ == "__main__":
    parser: ArgumentParser = ArgumentParser()
    parser.add_argument("--allowable", nargs="+", action="append", default=[], help="Allowable emoji codes")
    parser.add_argument("commitmsg", type=Path, help="Commit message")
    args: Namespace = parser.parse_args()

    main(args.allowable, args.commitmsg)
