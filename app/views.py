from rest_framework import generics, permissions, views
from django.contrib.auth import authenticate
from functools import reduce
from django.db import IntegrityError
from django.http import HttpRequest, HttpResponse, HttpResponseRedirect, JsonResponse
from rest_framework import generics, permissions, views
from django.shortcuts import render
from django.views.decorators.http import require_POST
from django.contrib.auth import authenticate, login, logout
from django.middleware import csrf
from django.templatetags.static import static

from app.serializers import BlogSerializer, BlogsListSerializer
from app.models import Blog, Comment, User

# Create your views here.


def spa_html(request: HttpRequest, resource: str):
    metadata = {
        "description": "This is the personal blogging site of Yewo Mhango",
        "title": "Yewo's Blog",
        "image": request.build_absolute_uri(
            static("preview-image.jpg")
        ),
        "url": request.build_absolute_uri(),
    }

    return render(request, 'index.html', metadata)


def homepage(request: HttpRequest):
    metadata = {
        "description": "This is the personal blogging site of Yewo Mhango",
        "title": "Yewo's Blog",
        "image": request.build_absolute_uri(
            static("preview-image.jpg")
        ),
        "url": request.build_absolute_uri(),
        "posts": Blog.objects.all().order_by("-date"),
    }

    return render(request, 'home.html', metadata)


def view_post_server_side(request: HttpRequest, post_slug: str):
    blog_post = Blog.objects.get(slug=post_slug)

    metadata = {
        "description": blog_post.summary,
        "title": blog_post.title,
        "image": request.build_absolute_uri(
            blog_post.thumbnail.url
        ),
        "url": request.build_absolute_uri(),
        "author": blog_post.author.__str__(),
        "post": blog_post,
    }

    return render(request, 'post.html', metadata)


def favicon(request: HttpRequest):
    return HttpResponseRedirect(static("favicon.ico"))


def view_post(request: HttpRequest, post_slug: str):
    blog_post = Blog.objects.get(slug=post_slug)
    return JsonResponse(BlogSerializer(blog_post).data)


class BlogsListView(generics.ListAPIView):
    serializer_class = BlogsListSerializer

    def get_queryset(self):
        qp = self.request.query_params

        # Search keywords, and page number for pagination
        keywords, page = qp.get("s") or "", qp.get("page")

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
            Blog.objects.filter(content__icontains=keywords),
        ).order_by("-date")


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
    return HttpResponse(csrf.get_token(request))


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


class UserAuthDetails(views.APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request: HttpRequest):
        user: User = request.user

        return JsonResponse({
            'authenticated': user.is_authenticated,
            'canpost': user.is_staff,
            'email': user.email if user.is_authenticated else "",
            'name': user.__str__() if user.is_authenticated else "",
        })


class PublishBlogPost(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request: HttpRequest):
        if not request.user.is_staff:
            return HttpResponse("You need to be a staff user to publish", status=401)

        reqDict = request.POST.dict()

        newBlog = Blog(
            title=reqDict["title"],
            summary=reqDict["summary"],
            content=reqDict["postContent"],
            image=request.FILES.get("thumbnail"),
            author=request.user
        )

        newBlog.save()

        return HttpResponse(newBlog.slug)


class UpdateBlogPost(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request: HttpRequest, post_slug: str):
        if not (request.user.is_staff):
            return HttpResponse("You need to be a staff user to publish", status=401)

        if not Blog.objects.filter(slug=post_slug).exists():
            return HttpResponse("The post does not exist", status=401)

        blog = Blog.objects.get(slug=post_slug)
        reqDict = request.POST.dict()

        blog.title = reqDict["title"]
        blog.summary = reqDict["summary"]
        blog.content = reqDict["postContent"]

        thumbnail = request.FILES.get("thumbnail")
        if thumbnail:
            blog.image = thumbnail

        blog.save()

        return HttpResponse("")


class PublishComment(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request: HttpRequest, post_slug: str):
        reqDict = request.POST.dict()

        reply_comment_id = reqDict.get("replying_to", None)
        reply_comment = Comment.objects.get(
            reply_comment_id
        ) if reply_comment_id != None else None

        comment = Comment(
            user=request.user,
            text=reqDict["text"],
            blop_post=Blog.objects.get(slug=post_slug),
            replying_to=reply_comment,
        )

        comment.save()

        return HttpResponse("")
