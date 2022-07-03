
from django.http import HttpRequest, HttpResponse, JsonResponse
from rest_framework import viewsets, generics
from django.shortcuts import render
from app.models import Blog

from app.serializers import BlogSerializer, BlogsListSerializer

# Create your views here.


def index(request: HttpRequest, resource: str):
    return render(request, 'index.html')


def publish(request: HttpRequest):
    reqDict = request.POST.dict()

    newBlog = Blog(title=reqDict["title"],
                   summary=reqDict["summary"],
                   content=reqDict["postContent"],
                   image=request.FILES.get("thumbnail"),
                   author=reqDict["userName"])

    newBlog.save()

    return HttpResponse(newBlog.slug)


def view_post(request: HttpRequest, post: str):
    blog_post = Blog.objects.get(slug=post)
    blog_post.views += 1
    blog_post.save()

    return JsonResponse(BlogSerializer(blog_post).data)


class BlogsListView(generics.ListAPIView):
    serializer_class = BlogsListSerializer

    def get_queryset(self):
        qp = self.request.query_params

        keywords, page = qp.get("s") or "", qp.get("page")

        print("Keywords:", keywords, "Page:", page)

        return Blog.objects.filter(content__contains=keywords).union(Blog.objects.filter(title__contains=keywords))
