from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager

class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)

class User(AbstractUser):
    username = None
    email = models.EmailField(unique=True, verbose_name="البريد الإلكتروني")
    phone_number = models.CharField(max_length=15, unique=True, verbose_name="رقم الهاتف")
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    profile_image_url = models.CharField(max_length=500, blank=True, null=True, verbose_name="رابط الصورة")
    
    USERNAME_FIELD = 'email' 
    REQUIRED_FIELDS = ['phone_number', 'full_name']

    objects = CustomUserManager()

    def __str__(self):
        return self.email
