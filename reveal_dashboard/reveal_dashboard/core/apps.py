from django.apps import AppConfig


class CoreConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'core'

    def ready(self):
        # تحميل الإشارات وتهيئة Firebase عند توفر الاعتمادات
        import core.firebase_config  # noqa: F401
        import core.signals  # noqa: F401
