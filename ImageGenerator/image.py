import os
import sys
import textwrap
from PIL import Image, ImageDraw, ImageFont


if __name__ == "__main__":
  if len(sys.argv) != 4:
    print("Needs 3 arguments!", sys.argv)
    sys.exit()

  title = sys.argv[1]
  date = sys.argv[2]
  output_path = sys.argv[3]
  image = Image.open('background.png')
  font_small = ImageFont.truetype('Roboto-Regular.ttf', 25, encoding='unic')
  font_big = ImageFont.truetype('Roboto-Regular.ttf', 55, encoding='unic')

  draw = ImageDraw.Draw(image)
  draw.text((30, 15), date, font=font_small, fill="#FFFFFF")

  offset = 60
  for line in textwrap.wrap(title, width=36):
      draw.text((30, offset), line, font=font_big, fill="#FFFFFF")
      offset += 70

  image.save(output_path, format="PNG")
