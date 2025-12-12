from django.db import models
from django.conf import settings
import uuid

class Cafe(models.Model):
    name = models.CharField(max_length=100, verbose_name="اسم المقصف")
    image = models.CharField(max_length=500, blank=True, null=True, verbose_name="صورة المقصف")
    location = models.CharField(max_length=200, blank=True, null=True, verbose_name="الموقع")
    owner = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='owned_cafe', verbose_name="مدير المقصف")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Category(models.Model):
    name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.name

class Product(models.Model):
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='products', verbose_name="المقصف")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products', verbose_name="التصنيف")
    name = models.CharField(max_length=100, verbose_name="اسم المنتج")
    description = models.TextField(verbose_name="الوصف", blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="السعر")
    image = models.CharField(max_length=500, verbose_name="رابط الصورة")
    is_available = models.BooleanField(default=True, verbose_name="متاح للطلب")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Order(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'قيد الانتظار'),
        ('PREPARING', 'جاري التحضير'),
        ('READY', 'جاهز للاستلام'),
        ('COMPLETED', 'مكتمل'),
        ('CANCELLED', 'ملغي'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='orders', verbose_name="الطالب")
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='orders', verbose_name="المقصف")
    total_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="الإجمالي")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', verbose_name="حالة الطلب")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="وقت الطلب")
    order_number = models.CharField(max_length=10, unique=True, blank=True, null=True, verbose_name="رقم الطلب")

    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = str(uuid.uuid4().int)[:8]
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Order #{self.order_number} - {self.user.full_name}"

class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1, verbose_name="الكمية")
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="سعر الوحدة", default=0.00)

    def __str__(self):
        return f"{self.quantity} x {self.product.name}"
