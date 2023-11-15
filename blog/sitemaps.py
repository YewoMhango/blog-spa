from django.contrib.sitemaps import Sitemap
from app.models import Blog


class BlogsSitemap(Sitemap):
    def items(self):
        return Blog.objects.all()

    def lastmod(self, obj: Blog):
        return obj.date
