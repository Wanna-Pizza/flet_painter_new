# Introduction

FletPainterEditor for Flet.

## Examples

```
import flet as ft

from flet_painter_editor import FletPainterEditor


def main(page: ft.Page):
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER

    page.add(

                ft.Container(height=150, width=300, alignment = ft.alignment.center, bgcolor=ft.Colors.PURPLE_200, content=FletPainterEditor(
                    tooltip="My new FletPainterEditor Control tooltip",
                    value = "My new FletPainterEditor Flet Control", 
                ),),

    )


ft.app(main)
```

## Classes

[FletPainterEditor](FletPainterEditor.md)


