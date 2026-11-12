from collections import namedtuple

from libfdt import Property as _Property

from dataclasses import InitVar, dataclass, field
from enum import IntEnum
from pathlib import PurePath
from typing import Literal, NamedTuple, Optional, cast
from weakref import ReferenceType as WeakRef

from .base import DTree, Property
from .overlay import DtOverlay


class _PropertyKind(IntEnum):
    UNKNOWN = 0

    U32 = 1
    I32 = 2
    U64 = 3
    I64 = 4

    U32List = 5
    I32List = 6
    U64List = 7
    I64List = 8

    String = 9
    StringList = 10

type PropertyValue = int | list[int] | str | list[str] | bytearray
type PropertyType = tuple[_PropertyKind, PropertyValue]

@dataclass(frozen = True, slots = True)
class TreeNodeProperty(NamedTuple):
    discriminant: _PropertyKind
    property: Property

    # def _get(self) -> PropertyType:
    def get(self) -> PropertyValue:
        match self.discriminant:
            case _PropertyKind.UNKNOWN:
                return cast(bytearray, self.property)
            case _PropertyKind.U32:
                return self.property.as_uint32()
            case _PropertyKind.I32:
                return self.property.as_int32()
            case _PropertyKind.U64:
                return self.property.as_uint64()
            case _PropertyKind.I64:
                return self.property.as_int64()
            case _PropertyKind.U32List:
                return self.property.as_uint32_list()
            case _PropertyKind.I32List:
                return self.property.as_int32_list()
            case _PropertyKind.U64List:
                return self.property.as_uint64_list()
            case _PropertyKind.I64List:
                return self.property.as_int64_list()
            case _PropertyKind.String:
                return self.property.as_str()
            case _PropertyKind.StringList:
                return self.property.as_stringlist()

    def __repr__(self) -> str:
        return repr(self.get())

    def __str__(self) -> str:
        return str(self.get())

@dataclass(frozen = True, slots = True)
class TreeNode:
    view: WeakRef["TreeViewBase"]
    parent: Optional[WeakRef["TreeNode"]] = field()

    offset: int
    phandle: int
    symbol: str

    properties: dict[str, TreeNodeProperty]
    children: dict[str, "TreeNode"]

    def get_item(self, name: str) -> Optional["PathItem"]:
        return self.children.get(name, self.properties.get(name, None))

type PathItem = TreeNode | TreeNodeProperty

class TreeViewBase[D: DTree]:
    tree: WeakRef[D]
    root: TreeNode = field(init=False)

    def resolve_path(self, path: PurePath) -> Optional[PathItem]:
        if not path.is_absolute():
            return None

        item: Optional[PathItem] = self.root
        for component in path.parts[1:]:
            item = cast(TreeNode, item).get_item(component)
            if item is None:
                return None

            elif not isinstance(item, TreeNode):
                break

        return item

class TreeView(TreeViewBase[DTree]):
    ...

class OverlayView(TreeViewBase[DtOverlay]):
    ...

