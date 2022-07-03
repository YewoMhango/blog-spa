from django.db import models
from django.utils.text import slugify

from imagekit.models import ImageSpecField  # < here
from pilkit.processors import ResizeToFill

# Create your models here.


class Blog(models.Model):
    title = models.CharField(max_length=128)
    summary = models.CharField(max_length=256)
    content = models.TextField()
    image = models.ImageField(default='', blank=True, upload_to='images')
    thumbnail = ImageSpecField(source='image',
                               processors=[ResizeToFill(480, 270)],
                               format='JPEG',
                               options={'quality': 60})
    date = models.DateTimeField(auto_now=True)
    slug = models.SlugField(blank=True, default="")
    author = models.CharField(max_length=128)
    views = models.PositiveIntegerField(default=0)

    def __str__(self):
        return self.title.value_to_string()

    def save(self, *args, **kwargs):
        self.slug = slugify(self.title)
        super(Blog, self).save()
