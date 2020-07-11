import os
from liquidluck.options import g
from liquidluck.utils import UnicodeDict
from liquidluck.writers.base import BaseWriter


class SitemapWriter(BaseWriter):
    writer_name = 'sitemap'

    def __init__(self):
        self._template = self.get('sitemap_template', 'sitemap.xml')
        self._output = self.get('sitemap_output', 'sitemap.xml')

    def start(self):
        dest = os.path.join(g.output_directory, self._output)
        self.render({}, self._template, dest)
