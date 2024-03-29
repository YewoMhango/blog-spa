from django.db import models
from django.urls import reverse
from django.utils.text import slugify
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.utils import timezone

from imagekit.models import ImageSpecField  # < here
from pilkit.processors import ResizeToFill

# Create your models here.


class UserManager(BaseUserManager):

    def _create_user(self, email, password, is_staff, is_superuser, **extra_fields):
        if not email:
            raise ValueError('Users must have an email address')
        now = timezone.now()
        email = self.normalize_email(email)
        user = self.model(
            email=email,
            is_staff=is_staff,
            is_active=True,
            is_superuser=is_superuser,
            last_login=now,
            date_joined=now,
            **extra_fields
        )
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password, **extra_fields):
        return self._create_user(email, password, False, False, **extra_fields)

    def create_superuser(self, email, password, **extra_fields):
        user = self._create_user(email, password, True, True, **extra_fields)
        return user


class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(max_length=254, unique=True)
    first_name = models.CharField(max_length=254, default="Unnamed")
    last_name = models.CharField(max_length=254, default="User")
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    last_login = models.DateTimeField(null=True, blank=True)
    date_joined = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = 'email'
    EMAIL_FIELD = 'email'
    REQUIRED_FIELDS = []

    objects = UserManager()

    def get_absolute_url(self):
        return "/users/%i/" % (self.pk)

    def __str__(self) -> str:
        return self.first_name + " " + self.last_name


class Blog(models.Model):
    title = models.CharField(max_length=128)
    summary = models.CharField(max_length=256)
    content = models.TextField()
    image = models.ImageField(default='', blank=True, upload_to='images')
    thumbnail = ImageSpecField(source='image',
                               processors=[ResizeToFill(480, 270)],
                               format='JPEG',
                               options={'quality': 60})
    date = models.DateTimeField(auto_now_add=True)
    slug = models.SlugField(blank=True, default="")
    author = models.ForeignKey(User, models.CASCADE)

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if self.slug.strip() == "":
            self.slug = slugify(self.title)
        super(Blog, self).save()

    def get_absolute_url(self):
        return reverse("view_post_server_side", args=[str(self.slug)])


class Comment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    text = models.TextField()
    blog_post = models.ForeignKey(Blog, on_delete=models.CASCADE)
    replying_to = models.ForeignKey(
        "Comment", null=True, blank=True, on_delete=models.CASCADE,
    )
    time_created = models.DateTimeField(auto_now_add=True)
    time_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.__str__()}: \"{self.text}\""
