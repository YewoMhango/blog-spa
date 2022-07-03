from .models import Blog
from rest_framework import serializers


class BlogSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()
    date = serializers.SerializerMethodField()

    class Meta:
        model = Blog
        fields = ("title", "summary", "author",
                  "date", "content", "image", "views")

    def get_image(self, obj: Blog):
        return obj.image.url

    def get_date(self, obj: Blog):
        return obj.date.strftime("%d %B, %Y")


class BlogsListSerializer(serializers.ModelSerializer):
    thumbnail = serializers.SerializerMethodField()
    url = serializers.SerializerMethodField()
    date = serializers.SerializerMethodField()

    class Meta:
        model = Blog
        fields = ("title", "summary", "slug", "thumbnail", "date", "url")

    def get_thumbnail(self, obj: Blog):
        return obj.thumbnail.url

    def get_url(self, obj: Blog):
        return "/post/" + obj.slug

    def get_date(self, obj: Blog):
        return obj.date.strftime("%d %B, %Y")
