from django.db import models
from django.utils.text import slugify

# Create your models here.
class Blog:
    title = models.CharField(max_length=128)
    subtitle = models.CharField(max_length=256)
    content = models.CharField()
    thumbnail = models.ImageField()
    published = models.DateTimeField(auto_now=True)
    slug = models.SlugField(blank=True, default="")

    def __str__(self):
        return self.title.value_to_string()

    def save(self, *args, **kwargs):
        self.slug = slugify(self.title)
        super(Blog, self).save()