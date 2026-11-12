from argparse import ArgumentParser
from fnmatch import fnmatch
import json
from pathlib import Path
import shutil

from device_trees.base import DTree
from device_trees.overlay import DtOverlay

def process_dtb(rel_path: Path, source: Path, destination: Path, overlays_data: list[DtOverlay]):
    source_dt = source / rel_path
    print(f"Processing source device tree {rel_path}...")
    dt = DTree(file_path = source_dt)

    for overlay in overlays_data:
        if overlay.filter and not fnmatch(str(rel_path), overlay.filter):
            print(f"  Skipping overlay {overlay.name}: filter '{overlay.filter}' is not in {str(rel_path)}")
            continue

        if len(dt.compatible) == 0:
            print(f"  Device tree {rel_path} has no compatible string set. Assuming it's compatible with overlay")
        elif not overlay.compatible.intersection(dt.compatible):
            print(f"  Skipping overlay {overlay.name}: {overlay.compatible} is incompatible with {dt.compatible}")
            continue

        print(f"  Applying overlay {overlay.name} ({overlay.file_path}) to {source_dt}")
        dt = overlay.apply(dt)

    print(f"Saving final device tree {rel_path}...")
    dest_path = destination / rel_path
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    dt.write(dest_path)

def parse_args():
    parser = ArgumentParser(description='Apply a list of overlays to a directory of device trees')

    parser.add_argument("--source", type=Path, help="Source directory")
    parser.add_argument("--destination", type=Path, help="Destination directory")
    parser.add_argument("--overlays", type=Path, help="JSON file with overlay descriptions")

    return parser.parse_args()

def main():
    args = parse_args()

    source: Path = args.source
    destination: Path = args.destination
    overlays: Path = args.overlays

    with overlays.open() as fd:
        overlays_data: list[DtOverlay] = [
            DtOverlay(
                name = item["name"],
                filter = item["filter"],
                file_path = Path(item["dtboFile"]),
            )
            for item in json.load(fd)
        ]

    for dirpath, _, filenames in source.walk():
        for filename in filenames:
            rel_path = (dirpath / filename).relative_to(source)
            if filename.endswith(".dtb"):
                process_dtb(rel_path, source, destination, overlays_data)
            else:
                # Copy other files through
                dest_path = destination / rel_path
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(source / rel_path, dest_path)


if __name__ == '__main__':
    main()
