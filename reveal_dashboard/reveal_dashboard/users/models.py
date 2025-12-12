from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager

class CustomUserManager(BaseUserManager):
    # Updated to use phone_number instead of email
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError('Phone number is required')
        # We don't normalize a phone number in the same way as an email
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    # Updated to use phone_number instead of email
    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        
        # You might want to ensure superusers have an email, even if optional for others
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(phone_number, password, **extra_fields)

class User(AbstractUser):
    username = None
    # Email is now optional and not unique
    email = models.EmailField(verbose_name="البريد الإلكتروني", blank=True, null=True)
    phone_number = models.CharField(max_length=15, unique=True, verbose_name="رقم الهاتف")
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    profile_image_url = models.CharField(max_length=500, blank=True, null=True, verbose_name="رابط الصورة")
    
    # Set phone_number as the main identifier
    USERNAME_FIELD = 'phone_number' 
    # full_name is now the only additional required field for createsuperuser
    REQUIRED_FIELDS = ['full_name', 'email']

    objects = CustomUserManager()

    def __str__(self):
        return self.phone_number
