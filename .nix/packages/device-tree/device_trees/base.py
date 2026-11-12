from libfdt import Fdt, FdtException, Property, FDT_ERR_NOTFOUND, FDT_ERR_BADOFFSET

from collections.abc import Iterator
from dataclasses import InitVar, dataclass, field
from functools import cached_property, cache
from pathlib import Path, PurePath
from typing import Optional, cast

from . import ROOT


@dataclass(frozen = True, kw_only = True, slots = True)
class DTree:
    file_path: Optional[Path] = field(default=None)
    fdt: Fdt = field(init=False)

    init_fdt: InitVar[Optional[Fdt]] = None

    def __post_init__(self, init_fdt: Optional[Fdt]):
        if init_fdt is None and self.file_path is not None:

            with self.file_path.open("rb") as fd:
                object.__setattr__(self, "fdt", Fdt(fd.read()))

        elif init_fdt is not None:
            object.__setattr__(self, "fdt", init_fdt)

        else:
            raise ValueError("Cannot initialize DTree.fdt: neither file_path nor init_fdt was provided")

    @cached_property
    def compatible(self) -> set[str]:
        if (compatible := self.prop_at("/compatible")) is not None:
            return set(compatible.as_stringlist())
        else:
            return set()

    @cache
    def offset(self, of: PurePath) -> Optional[int]:
        try:
            return self.fdt.path_offset(str(of))
        except FdtException as e:
            if e.err == -FDT_ERR_NOTFOUND:
                return None
            raise

    @cache
    def path_at_offset(self, offset: int) -> Optional[str]:
        try:
            return cast(str, self.fdt.get_path(offset))
        except FdtException as e:
            if e.err == -FDT_ERR_BADOFFSET:
                return None
            raise

    def grow(self, num_bytes: int) -> None:
        self.fdt.resize(self.fdt.totalsize() + num_bytes)

    def pack(self) -> None:
        self.fdt.pack()

    @cache
    def nodes_at_path(self, path: PurePath = ROOT) -> Optional[list[str]]:
        try:
            offset = self.offset(path)
            names = []

            child = self.fdt.first_subnode(offset)
            names.append(self.fdt.get_name(child))
            while True:
                try:
                    child = self.fdt.next_subnode(child)
                    names.append(self.fdt.get_name(child))
                except FdtException as e:
                    if e.err == -FDT_ERR_NOTFOUND:
                        break
                    raise

            return names
        except FdtException as e:
            if e.err == -FDT_ERR_NOTFOUND:
                return None
            raise

    @cache
    def props_at_path(self, path: PurePath = ROOT) -> Optional[dict[str, Property]]:
        offset = self.offset(path)
        if offset is None: return None

        try:
            prop_offset = self.fdt.first_property_offset(offset)
            props: dict[str, Property] = {}

            while True:
                try:
                    prop = self.fdt.get_property_by_offset(prop_offset)
                    props[prop.name] = prop
                    prop_offset = self.fdt.next_property_offset(prop_offset)
                except FdtException as e:
                    if e.err == -FDT_ERR_NOTFOUND:
                        break
                    raise

            return props
        except FdtException as e:
            if e.err == -FDT_ERR_NOTFOUND:
                return None
            raise

    @cache
    def prop_at(self, path: PurePath) -> Optional[Property]:
        #   cannot get any property using a relative path.
        #   cannot get a property at root. leading slash is a 'part', so
        #   the path cannot be the root if there are at least 2 parts.
        if not path.is_absolute() or len(path.parts) < 2:
            return None

        offset = self.offset(path.parent)
        if offset is None:
            return None

        try:
            # print("===")
            # print(f"parent: {path.parent}")
            # print(f"offset: {offset}")
            # print(f"name: {path.name}")
            return self.fdt.getprop(offset, path.name)
        except FdtException as e:
            if e.err == -FDT_ERR_NOTFOUND:
                return None
            raise

    def walk(self, path: PurePath = ROOT) -> Iterator[tuple[PurePath, list[str], dict[str, Property]]]:
        """
        Starting at the provided path (`/` by default), walk the tree and
        yield (current path, nodes in path, properties in path)
        """
        nodes: list[str] = self.nodes_at_path(path) or []
        props: dict[str, Property] = self.props_at_path(path) or {}
        yield path, nodes, props

        for node in nodes:
            yield from self.walk(path / node)

    def write(self, out_path: Optional[Path] = None) -> None:
        if self.file_path is None and out_path is None:
            raise ValueError("Cannot write DTB to file, no filepath was provided")

        with cast(Path, out_path or self.file_path).open("wb") as fd:
            fd.write(self.fdt.as_bytearray())

    def print(self, include_properties: bool = True, max_depth: Optional[int] = None) -> None:
        lasts: dict[PurePath, str] = dict()

        def iter_ancestry(path: PurePath) -> Iterator[tuple[PurePath, str]]:
            return zip(
                map(lambda p: PurePath(*p.parts), reversed(path.parents)),
                path.parent.parts[1:],
            )

        LINE_PREFIX = str()
        CONTENT = "\n/\n"
        def push_strs(*args: str) -> Optional[str]:
            nonlocal CONTENT, LINE_PREFIX
            CONTENT += LINE_PREFIX + (f"\n{LINE_PREFIX}".join(args) + "\n")


        for path, nodes, properties in self.walk():
            if nodes:
                lasts[path] = nodes[-1]

            if max_depth and len(path.parts) - 1 > max_depth:
                continue

            items = [
                "║ " if current != (lasts[ancestor] or None) else "  "
                for ancestor, current in iter_ancestry(path)
            ]
            LINE_PREFIX = "  ".join(items) + ("  " if len(items) > 0 else "")

            is_last_node = path.name == (lasts[path.parent] or None)
            if path != path.parent:
                if is_last_node:
                    push_strs(f"╚═> {path.name}")
                else:
                    push_strs(f"╠═> {path.name}")

            if include_properties and properties:
                if path != path.parent:
                    if is_last_node:
                        LINE_PREFIX += "    "
                    else:
                        LINE_PREFIX += "║   "

                last_prop: str = next(reversed(properties.keys()))
                for name in properties.keys():
                    if name != last_prop or nodes:
                        push_strs(f"╠═> {name}")
                    else:
                        push_strs(f"╚═> {name}")

                if nodes:
                    push_strs(f"║", "║ [Nodes]")

        print(CONTENT)



