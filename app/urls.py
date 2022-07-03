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
from rest_framework import routers

from . import views


# router = routers.DefaultRouter()
# router.register('hospitals', views.HospitalsViewSet)
# router.register('diseases', views.DiseaseTypesViewSet)
# router.register('disease_types', views.DiseaseTypesViewSet)


urlpatterns = [
    # path('', include(router.urls)),
    path('api/posts', views.BlogsListView.as_view(), name="posts"),
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    path('', views.index, {'resource': ''}, name='index'),
    path('<path:resource>', views.index, name='index')
]
