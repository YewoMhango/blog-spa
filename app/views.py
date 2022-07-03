from rest_framework import viewsets, generics
from django.shortcuts import render
from app.models import Blog

from app.serializers import BlogsListSerializer

# Create your views here.


def index(request, resource):
    return render(request, 'index.html')


class BlogsListView(generics.ListAPIView):
    serializer_class = BlogsListSerializer

    def get_queryset(self):
        qp = self.request.query_params

        keywords, page = qp.get("s") or "", qp.get("page")

        print(keywords, page)

        return Blog.objects.filter(content__contains=keywords)
