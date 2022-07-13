
from functools import reduce
from django.db import IntegrityError
from django.http import HttpRequest, HttpResponse, JsonResponse
from rest_framework import generics
from django.shortcuts import render
from django.views.decorators.http import require_POST
from django.contrib.auth import authenticate, login, logout

from app.serializers import BlogSerializer, BlogsListSerializer
from app.models import Blog, User

# Create your views here.


def index(request: HttpRequest, resource: str):
    return render(request, 'index.html')


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

        return reduce(
            lambda qs, keyword:
                qs.union(
                    Blog.objects.filter(title__icontains=keyword)
                ).union(
                    Blog.objects.filter(content__icontains=keyword)
                ).union(
                    Blog.objects.filter(summary__icontains=keyword)
                ).union(
                    Blog.objects.filter(author__first_name__icontains=keyword)
                ).union(
                    Blog.objects.filter(author__last_name__icontains=keyword)
                ),
            keywords.split(),
            Blog.objects.filter(content__icontains=keywords)
        )


@require_POST
def login_view(request: HttpRequest):
    email = request.POST["email"]
    password = request.POST["password"]

    if email is None or password is None:
        return HttpResponse("Please provide email and password", status=400)

    user = authenticate(email=email, password=password)

    if user is None:
        return HttpResponse("Invalid credential", status=400)

    login(request, user)
    return HttpResponse("Successfully logged in")


@require_POST
def sign_up(request: HttpRequest):
    email = request.POST["email"]
    password = request.POST["password"]
    firstname = request.POST["firstname"]
    lastname = request.POST["lastname"]

    try:
        user = User.objects.create_user(
            email, password, first_name=firstname, last_name=lastname)

        if user is None:
            return HttpResponse("Account creation failed", status=500)

        login(request, user)
        return HttpResponse("Account created successfully")

    except IntegrityError:
        return HttpResponse("User with the given email already exists", status=400)


def logout_view(request: HttpRequest):
    if request.user.is_authenticated:
        logout(request)

    return HttpResponse("Successfully logged out")


def who_am_i(request: HttpRequest):
    return JsonResponse(
        {'authenticated': request.user.is_authenticated,
         'canpost': request.user.is_staff}
    )


@require_POST
def publish(request: HttpRequest):
    if not request.user.is_authenticated:
        return HttpResponse("You need to login", status=401)

    reqDict = request.POST.dict()

    newBlog = Blog(title=reqDict["title"],
                   summary=reqDict["summary"],
                   content=reqDict["postContent"],
                   image=request.FILES.get("thumbnail"),
                   author=request.user)

    newBlog.save()

    return HttpResponse(newBlog.slug)
