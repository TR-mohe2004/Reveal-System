from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager

class CustomUserManager(BaseUserManager):
    # ✅ التعديل: الاعتماد على email بدلاً من phone_number كمعرف أساسي
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('يجب إدخال البريد الإلكتروني')
        
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, password, **extra_fields)

class User(AbstractUser):
    username = None # ✅ إلغاء اسم المستخدم التقليدي
    
    # ✅ البريد الإلكتروني هو المعرف الأساسي (Unique)
    email = models.EmailField(verbose_name="البريد الإلكتروني", unique=True)
    
    # رقم الهاتف موجود لكنه ليس وسيلة الدخول الأساسية
    phone_number = models.CharField(max_length=15, unique=True, verbose_name="رقم الهاتف")
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    profile_image_url = models.CharField(max_length=500, blank=True, null=True, verbose_name="رابط الصورة")
    
    # ✅ هذا هو المفتاح: الدخول عن طريق الإيميل
    USERNAME_FIELD = 'email'
    
    # الحقول المطلوبة عند إنشاء أدمن (غير الإيميل والباسورد)
    REQUIRED_FIELDS = ['full_name', 'phone_number']

    objects = CustomUserManager()

    def __str__(self):
        return self.email   