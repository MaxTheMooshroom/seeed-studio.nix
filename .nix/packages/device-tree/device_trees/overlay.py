from libfdt import Fdt, FdtException, FDT_ERR_NOSPACE, FDT_ERR_NOTFOUND, fdt_overlay_apply

from dataclasses import dataclass, field
from pathlib import Path, PurePath
from typing import ClassVar, Optional

from . import ROOT, filter_prefixed
from .base import DTree

@dataclass(frozen = True, kw_only = True, slots = True)
class DtOverlay(DTree):
    name: str = field()
    filter: str = field()

    # magic number of more space taken from fdtoverlay
    SIZE: ClassVar[int] = 65536

    @classmethod
    def from_dtree(cls, dtree: DTree, name: str, filter: str) -> "DtOverlay":
        return cls(
            file_path = dtree.file_path,
            init_fdt = dtree.fdt,
            name = name,
            filter = filter,
        )

    def apply(self, base: DTree, out_path: Optional[Path] = None) -> DTree:
        while True:
            # we need to copy the buffers because they can be left in an inconsistent
            # state if the operation fails (ref: fdtoverlay source)
            buf = base.fdt.as_bytearray().copy()
            err = fdt_overlay_apply(buf, self.fdt.as_bytearray().copy())

            if err == 0:
                new = DTree(
                    file_path = out_path or base.file_path,
                    init_fdt = Fdt(buf)
                )
                # trim the extra space from the final tree
                new.pack()
                return new

            elif err == -FDT_ERR_NOSPACE:
                # not enough space, add some blank space and try again
                base.grow(DtOverlay.SIZE)

            else:
                if err == -FDT_ERR_NOTFOUND:
                    self.validate_for(base)
                raise FdtException(err)

    @staticmethod
    def _filter_pathlist(pathlist: list[PurePath]) -> list[PurePath]:
        return filter_prefixed(
            pathlist,
            sort_key = lambda x: sum(map(len, x.parts)),
            prefix_check = lambda longer, shorter: longer.parts[:len(shorter.parts)] == shorter.parts,
        )

    def analyze(self, base: DTree) -> dict[str, list[PurePath]]:
        updates: list[PurePath] = []
        additions: list[PurePath] = []
        missing: list[PurePath] = []

        symbols = base.props_at_path(ROOT / "__symbols__") or {}
        fixups = self.props_at_path(ROOT / "__fixups__") or {}

        # Map external fixup locations to their base-tree target paths.
        external_targets: dict[PurePath, PurePath] = {}

        for symbol, prop in fixups.items():
            symbol_prop = symbols.get(symbol)
            if symbol_prop is None:
                continue

            target_path = PurePath(symbol_prop.as_stringlist()[0])

            for location in prop.as_stringlist():
                node_path, prop_name, _ = location.rsplit(":", 2)
                external_targets[PurePath(node_path) / prop_name] = target_path

        fragments = self.nodes_at_path(ROOT) or []

        for fragment in fragments:
            fragment_path = ROOT / fragment
            overlay_path = fragment_path / "__overlay__"

            if self.offset(overlay_path) is None:
                continue

            # Resolve the fragment target.
            target_path_prop = self.prop_at(fragment_path / "target-path")
            target_prop = self.prop_at(fragment_path / "target")

            if target_path_prop is not None:
                target_path = PurePath(target_path_prop.as_stringlist()[0])

            elif target_prop is not None:
                target_value = int.from_bytes(target_prop, "big")

                if target_value == 0xFFFFFFFF:
                    target_path = external_targets.get(fragment_path / "target")
                    if target_path is None:
                        missing.append(fragment_path)
                        continue

                else:
                    target_offset = base.fdt.node_offset_by_phandle(target_value)
                    path = base.path_at_offset(target_offset)
                    if path is None:
                        missing.append(fragment_path)
                        continue
                    target_path = PurePath(path)

            else:
                missing.append(fragment_path)
                continue

            # Verify that the target exists.
            if base.offset(target_path) is None:
                missing.append(target_path)
                continue

            # Compare the overlay contents against the target subtree.
            for path, _, props in self.walk(overlay_path):
                relative = path.relative_to(overlay_path)
                base_path = target_path / relative

                if relative != ROOT:
                    if base.offset(base_path) is None:
                        additions.append(base_path)
                    else:
                        updates.append(base_path)

                for name in props:
                    prop_path = base_path / name

                    if base.prop_at(prop_path) is None:
                        additions.append(prop_path)
                    else:
                        updates.append(prop_path)

        return {
            "updates": self._filter_pathlist(updates),
            "additions": self._filter_pathlist(additions),
            "missing": self._filter_pathlist(missing),
        }

    def validate_for(self, base: DTree) -> None:
        analysis = self.analyze(base)
        print(f"updates: {analysis["updates"]}")
        print(f"additions: {analysis["additions"]}")
        missing = analysis["missing"]
        print(f"missing: {missing}")

        if len(missing) > 0:
            print(f"dt-overlay {self.name} targets one or more nonexistent paths in a base tree located at {base.file_path}:")

        for path in missing:
            print(f"    > {path}")

        if len(missing) > 0:
            exit(1)

