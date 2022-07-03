from .models import Blog
from rest_framework import serializers


class BlogSerializer(serializers.ModelSerializer):
    class Meta:
        model = Blog
        fields = ('id', 'name')


class BlogsListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Blog
        fields = ("title", "summary", "thumbnail", "slug")
