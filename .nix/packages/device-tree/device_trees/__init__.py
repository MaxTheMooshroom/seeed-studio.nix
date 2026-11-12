import jsonschema
from referencing import Registry, Resource
import yaml

from dataclasses import InitVar, dataclass, field
from pathlib import Path, PurePath
from typing import TYPE_CHECKING, Callable

if TYPE_CHECKING: from _typeshed import SupportsRichComparison


ROOT = PurePath("/")

def filter_prefixed[T, R: SupportsRichComparison](
        items: list[T],
        sort_key: Callable[[T], R] = len,
        prefix_check: Callable[[T, T], bool] = str.startswith,
    ) -> list[T]:
    """Remove any string-like objects that are prefixed by the entirety of another item in the list"""
    items.sort(key = sort_key)
    return [
        s for i, s in enumerate(items)
        if not any(prefix_check(s, prefix) for prefix in items[:i])
    ]

@dataclass(frozen = True, slots = True)
class EvaluationContext:
    kernel_sources: InitVar[list[Path]]
    extra_libs: InitVar[list[Path]]

    schemas: Registry = field(init = False)

    def __post_init__(self, kernel_sources: list[Path], extra_libs: list[Path]):
        registry = Registry()

        def crawl(path: Path):
            nonlocal registry

            for source in path.rglob("*.yaml"):
                schema = yaml.safe_load(source.read_text(encoding="utf-8"))
                registry = registry.with_resource(
                    schema["$id"],
                    Resource.from_contents(schema)
                )

        for dir in kernel_sources:
            crawl(dir / "Documentation/devicetree/bindings")

        for dir in extra_libs:
            crawl(dir)


