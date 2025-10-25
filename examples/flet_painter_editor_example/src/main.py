import flet as ft

import base64
from PIL import Image
import io
from assets.fonts import FONTS
import random

from flet_painter_editor import (
    FletPainter,
    TextWidget,
    ImageWidget,
    SaveEvent,
)


def main(page: ft.Page):
    page.fonts = FONTS
    page.update()

    def on_edit(e):
        image_editor.change_text(
            font_family=random.choice(list(FONTS.keys())),
        )

    def on_save(e: SaveEvent):
        if e.bytes:
            image = Image.open(io.BytesIO(e.bytes))
            width, height = image.size
            print(f"Image dimensions: {width}x{height}")

            base64_data = base64.b64encode(e.bytes).decode()
            
            print(f"Save event received with {len(e.bytes)} bytes")
            page.overlay.append(
                ft.Container(
                    ft.Image(
                        src_base64=base64_data,
                        width=300,
                        height=300,
                        fit=ft.ImageFit.CONTAIN
                    ),
                    bgcolor='black'
                )
            )
            page.update()



    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER

    image_editor = FletPainter(
        layers=[
            TextWidget(
                text="Hello from Flet Image Editor!",
            )
        ],
        on_save=on_save,
    )

    page.add(
        ft.Container(
            height=500, 
            width=500, 
            alignment = ft.alignment.center, 
            bgcolor=ft.Colors.PURPLE_200, 
            content=image_editor
            ),
        ft.Row([
            ft.ElevatedButton(
                "add Image",
                on_click=lambda e: image_editor.add_image(
                    "/Users/mf/Albert_Designer/src/assets/splash.png"
                )
            ),
            ft.ElevatedButton(
                "add Text",
                on_click=lambda e: image_editor.add_text("New Text Widget", color="#868686")
            ),
            ft.ElevatedButton(
                "Save",
                on_click=lambda e: image_editor.save_image_bytes()
            ),
            ft.ElevatedButton(
                "Edit",
                on_click=on_edit
            )
        
        ])

    )


ft.app(main)
