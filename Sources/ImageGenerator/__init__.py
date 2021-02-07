import os
import sys
import textwrap
from PIL import Image, ImageDraw, ImageFont

class ImageGenerator:
    def __init__(self, path):
        self._image = Image.open(path+'/ImageGenerator/background.png')
        self.font_small = ImageFont.truetype(path+'/ImageGenerator/Roboto-Regular.ttf', 25, encoding='unic')
        self.font_big = ImageFont.truetype(path+'/ImageGenerator/Roboto-Regular.ttf', 55, encoding='unic')

    def generate(self, title, date, output_path):
        image = self._image.copy()

        draw = ImageDraw.Draw(image)
        draw.text((30, 15), date, font=self.font_small, fill="#FFFFFF")

        offset = 60
        for line in textwrap.wrap(title, width=36):
            draw.text((30, offset), line, font=self.font_big, fill="#FFFFFF")
            offset += 70

        image.save(output_path, format="PNG")
