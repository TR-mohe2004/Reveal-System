from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # رابط لوحة تحكم الأدمن الخاصة بـ Django
    path('admin/', admin.site.urls),
    
    # ✅ التعديل الحاسم:
    # نوجه كل الطلبات (سواء كانت للداشبورد أو للـ API) إلى ملف core.urls
    # لأننا قمنا بتعريف مسارات مثل 'api/login' و 'dashboard/' داخله
    path('', include('core.urls')),
]

# إعدادات ملفات الميديا (الصور)
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)    