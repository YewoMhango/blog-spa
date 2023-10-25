"""app URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import include, path

from . import views

urlpatterns = [
    path('favicon.ico', views.favicon, name='favicon'),
    path("api/post/<slug:post_slug>", views.view_post, name='view_post'),
    path('api/publish', views.publish, name='publish'),
    path(
        'api/update_post/<slug:post_slug>',
        views.update_post,
        name='update_post',
    ),
    path('api/posts', views.BlogsListView.as_view(), name="posts"),
    path('api/sign-up', views.sign_up, name="sign-up"),
    path('api/login', views.login_view, name="login"),
    path('api/logout', views.logout_view, name="logout"),
    path('api/user-details', views.user_auth_details, name="user-details"),
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    path('', views.index, {'resource': ''}, name='index'),
    path('<path:resource>', views.index, name='index')
]
