#!/usr/bin/env python3

from argparse import ArgumentParser
from pathlib import Path

from device_trees import EvaluationContext

def arg_parse():
    parser = ArgumentParser(description="Resolve a device-tree overlay against a base tree using schema bindings")

    parser.add_argument("overlay", type = Path, help = "The absolute path of the overlay (compiled)")
    parser.add_argument("base", type = Path, help = "The absolute path of the base device-tree to apply to (compiled)")

    parser.add_argument("-k", "--kernel-tree", dest = "kernel_sources", type = Path, action = "append", default = [])
    parser.add_argument("-L", "--extra-schema-lib", dest = "extra_libs", type = Path, action = "append", default = [])

    return parser.parse_args()

def main():
    args = arg_parse()

    # TODO: Check validity of path arguments and flags. Invalid flags emit a warning and get skipped.

    ctx = EvaluationContext(args.kernel_sources, args.extra_libs)

    # ...


if __name__ == "__main__":
    main()

