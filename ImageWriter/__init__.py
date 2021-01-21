import os
import textwrap
import HTMLParser
from PIL import Image, ImageDraw, ImageFont
from liquidluck.options import g
from liquidluck.writers.base import BaseWriter


class ImageWriter(BaseWriter):
    writer_name = 'image'

    def __init__(self):
        self._image = Image.open('ImageWriter/background.png')

    def start(self):
        font_small = ImageFont.truetype('ImageWriter/Roboto-Regular.ttf', 25, encoding='unic')
        font_big = ImageFont.truetype('ImageWriter/Roboto-Regular.ttf', 55, encoding='unic')

        for post in g.public_posts:
            dest = os.path.join(g.output_directory, 'static', 'images', post.filename + '.png')
            title = HTMLParser.HTMLParser().unescape(post.title)
            
            image = self._image.copy()

            draw = ImageDraw.Draw(image)
            draw.text((30, 15), post.date.strftime('%B %d, %Y'), font=font_small, fill="#FFFFFF")

            offset = 60
            for line in textwrap.wrap(title, width=36):
                draw.text((30, offset), line, font=font_big, fill="#FFFFFF")
                offset += 70

            image.save(dest, format="PNG", optimize=True)