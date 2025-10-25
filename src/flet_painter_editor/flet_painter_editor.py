import json
from dataclasses import dataclass, field
from typing import Any, Callable, Optional, Union, List, Dict

from flet.core.adaptive_control import AdaptiveControl
from flet.core.constrained_control import ConstrainedControl
from flet.core.control import Control, OptionalNumber
from flet.core.control_event import ControlEvent
from flet.core.event_handler import EventHandler
from flet.core.ref import Ref
from flet.core.tooltip import TooltipValue
from flet.core.types import (
    OptionalControlEventCallable,
    OptionalEventCallable,
    ResponsiveNumber,
)
from flet.core.alignment import Alignment
from flet.core.animation import AnimationValue
from flet.core.badge import BadgeValue
from flet.core.types import (
    MarginValue,
    OffsetValue,
    RotateValue,
    ScaleValue,
)

__all__ = ["FletPainter", "ImageWidget", "TextWidget", "TextEvent"]


@dataclass
class ImageWidget:
    type: str = "image"  # DONT CHANGE THIS
    path: str = None
    x: Optional[float] = None
    y: Optional[float] = None
    scale: Optional[float] = None  # New field for scale, default is None


@dataclass
class TextWidget:
    type: str = "text"  # DONT CHANGE THIS
    text: str = None
    x: Optional[float] = None
    y: Optional[float] = None
    font_size: Optional[float] = None
    color: Optional[str] = None
    font_weight: Optional[str] = None


class TextEvent(ControlEvent):
    def __init__(self, e: ControlEvent):
        super().__init__(e.target, e.name, e.data, e.control, e.page)
        if e.data:
            d = json.loads(e.data)
            self.value: Optional[str] = d.get("value")
            self.style: Optional[Dict] = d.get("style")
        else:
            self.value = None
            self.style = None


class SaveEvent(ControlEvent):
    def __init__(self, e: ControlEvent):
        super().__init__(e.target, e.name, e.data, e.control, e.page)
        self.bytes: Optional[bytes] = None
        if e.data:
            import base64
            self.bytes = base64.b64decode(e.data)


class FletPainter(ConstrainedControl, AdaptiveControl):
    """
    FletPainter Control - A drawing canvas for Flet applications.
    """

    def __init__(
        self,
        # FletPainter specific
        layers: Optional[List[Dict[str, Any]]] = None,
        on_selected_text: Optional[Callable[[TextEvent], None]] = None,
        on_text_double_tap: Optional[Callable[[TextEvent], None]] = None,
        on_save: Optional[Callable[[SaveEvent], None]] = None,
        #
        # ConstrainedControl and AdaptiveControl
        #
        ref: Optional[Ref] = None,
        key: Optional[str] = None,
        width: OptionalNumber = None,
        height: OptionalNumber = None,
        left: OptionalNumber = None,
        top: OptionalNumber = None,
        right: OptionalNumber = None,
        bottom: OptionalNumber = None,
        expand: Union[None, bool, int] = None,
        expand_loose: Optional[bool] = None,
        col: Optional[ResponsiveNumber] = None,
        opacity: OptionalNumber = None,
        rotate: Optional[RotateValue] = None,
        scale: Optional[ScaleValue] = None,
        offset: Optional[OffsetValue] = None,
        aspect_ratio: OptionalNumber = None,
        animate_opacity: Optional[AnimationValue] = None,
        animate_size: Optional[AnimationValue] = None,
        animate_position: Optional[AnimationValue] = None,
        animate_rotation: Optional[AnimationValue] = None,
        animate_scale: Optional[AnimationValue] = None,
        animate_offset: Optional[AnimationValue] = None,
        on_animation_end: OptionalControlEventCallable = None,
        tooltip: Optional[TooltipValue] = None,
        badge: Optional[BadgeValue] = None,
        visible: Optional[bool] = None,
        disabled: Optional[bool] = None,
        data: Any = None,
        adaptive: Optional[bool] = None,
    ):
        ConstrainedControl.__init__(
            self,
            ref=ref,
            key=key,
            width=width,
            height=height,
            left=left,
            top=top,
            right=right,
            bottom=bottom,
            expand=expand,
            expand_loose=expand_loose,
            col=col,
            opacity=opacity,
            rotate=rotate,
            scale=scale,
            offset=offset,
            aspect_ratio=aspect_ratio,
            animate_opacity=animate_opacity,
            animate_size=animate_size,
            animate_position=animate_position,
            animate_rotation=animate_rotation,
            animate_scale=animate_scale,
            animate_offset=animate_offset,
            on_animation_end=on_animation_end,
            tooltip=tooltip,
            badge=badge,
            visible=visible,
            disabled=disabled,
            data=data,
        )

        AdaptiveControl.__init__(self, adaptive=adaptive)

        # Event handlers setup
        self.__on_selected_text = EventHandler(lambda e: TextEvent(e))
        self._add_event_handler("selected_text", self.__on_selected_text.get_handler())
        self.__on_text_double_tap = EventHandler(lambda e: TextEvent(e))
        self._add_event_handler("on_text_double_tap", self.__on_text_double_tap.get_handler())
        self.__on_save = EventHandler(lambda e: SaveEvent(e))
        self._add_event_handler("on_save", self.__on_save.get_handler())

        # Properties
        self.layers = layers
        self.on_selected_text = on_selected_text
        self.on_text_double_tap = on_text_double_tap
        self.on_save = on_save

    def _get_control_name(self):
        return "flet_painter_editor"

    def before_update(self):
        super().before_update()
        self._set_attr_json("layers", self.__layers)

    # ===== Methods =====

    def add_text(self,
                 text: str = None,
                 font_family: Optional[str] = None,
                 x: Optional[float] = None,
                 y: Optional[float] = None,
                 font_size: Optional[float] = None,
                 color: Optional[str] = None,
                 font_weight: Optional[str] = None) -> None:
        self.invoke_method(
            "addText",
            arguments={
                "text": text,
                "fontFamily": font_family,
                "x": str(x) if x is not None else None,
                "y": str(y) if y is not None else None,
                "fontSize": str(font_size) if font_size is not None else None,
                "color": color,
                "fontWeight": font_weight,
            }
        )

    def add_image(self,
                  path: str = None,
                  x: Optional[float] = None,
                  y: Optional[float] = None,
                  scale: Optional[float] = None
                  ) -> None:
        self.invoke_method(
            "addImage",
            arguments={
                "path": path,
                "x": str(x) if x is not None else None,
                "y": str(y) if y is not None else None,
                "scale": str(scale) if scale is not None else None,
            }
        )

    def save_image(self, path: str = None, scale: float = None) -> None:
        self.invoke_method(
            "saveImage",
            arguments={
                "path": path,
                "scale": str(scale) if scale is not None else None,
            }
        )

    def change_text(self,
                    text: str = None,
                    font_family: Optional[str] = None,
                    x: Optional[float] = None,
                    y: Optional[float] = None,
                    font_size: Optional[float] = None,
                    color: Optional[str] = None) -> None:
        self.invoke_method(
            "changeText",
            arguments={
                "text": text,
                "fontFamily": font_family,
                "x": str(x) if x is not None else None,
                "y": str(y) if y is not None else None,
                "fontSize": str(font_size) if font_size is not None else None,
                "color": color,
            }
        )

    def delete_selected(self):
        """Delete selected object."""
        self.invoke_method("deleteSelected")

    def focus(self):
        """Focus the canvas."""
        self.invoke_method("focus")

    # ===== Properties =====

    # layers
    @property
    def layers(self) -> Optional[List[Dict[str, Any]]]:
        return self.__layers

    @layers.setter
    def layers(self, value: Optional[List[Dict[str, Any]]]):
        self.__layers = value if value is not None else []

    # on_selected_text
    @property
    def on_selected_text(self) -> Optional[Callable[[TextEvent], None]]:
        return self.__on_selected_text.handler

    @on_selected_text.setter
    def on_selected_text(self, handler: Optional[Callable[[TextEvent], None]]):
        self.__on_selected_text.handler = handler

    # on_text_double_tap
    @property
    def on_text_double_tap(self) -> Optional[Callable[[TextEvent], None]]:
        return self.__on_text_double_tap.handler

    @on_text_double_tap.setter
    def on_text_double_tap(self, handler: Optional[Callable[[TextEvent], None]]):
        self.__on_text_double_tap.handler = handler

    # on_save
    @property
    def on_save(self) -> Optional[Callable[[SaveEvent], None]]:
        return self.__on_save.handler

    @on_save.setter
    def on_save(self, handler: Optional[Callable[[SaveEvent], None]]):
        self.__on_save.handler = handler

    def save_image_bytes(self, scale: float = None) -> None:
        self.invoke_method(
            "saveImageBytes",
            arguments={
                "scale": str(scale) if scale is not None else None,
            }
        )