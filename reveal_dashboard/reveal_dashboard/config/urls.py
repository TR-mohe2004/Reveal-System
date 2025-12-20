from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # رابط لوحة تحكم الأدمن الخاصة بـ Django
    path('admin/', admin.site.urls),
    
    # ✅ 1. توجيه روابط التطبيق (API)
    # أي رابط يبدأ بكلمة api/ سيذهب فوراً إلى ملف core/api_urls.py
    path('api/', include('core.api_urls')),

    # ✅ 2. توجيه روابط الموقع (الداش بورد)
    # أي رابط آخر (مثل dashboard/, login/) سيذهب إلى ملف core/urls.py
    path('', include('core.urls')),
]

# إعدادات ملفات الميديا (الصور)
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)