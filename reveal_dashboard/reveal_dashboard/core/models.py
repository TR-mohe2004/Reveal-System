from django.db import models
from django.conf import settings
import uuid


class Cafe(models.Model):
    name = models.CharField(max_length=100, verbose_name="اسم المقهى")
    image = models.CharField(max_length=500, blank=True, null=True, verbose_name="صورة المقهى")
    location = models.CharField(max_length=200, blank=True, null=True, verbose_name="الموقع")
    owner = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='my_cafe',
        verbose_name="مالك المقهى"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Category(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class Product(models.Model):
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='products', verbose_name="المقهى")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products', verbose_name="الفئة")
    name = models.CharField(max_length=100, verbose_name="اسم المنتج")
    description = models.TextField(verbose_name="الوصف", blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="السعر")
    image = models.CharField(max_length=500, verbose_name="رابط الصورة")
    is_available = models.BooleanField(default=True, verbose_name="متاح")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Order(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'قيد الانتظار'),
        ('PREPARING', 'قيد التحضير'),
        ('READY', 'جاهز'),
        ('COMPLETED', 'مكتمل'),
        ('CANCELLED', 'ملغى'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='orders', verbose_name="العميل")
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='orders', verbose_name="المقهى")
    total_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="الإجمالي")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', verbose_name="الحالة")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاريخ الطلب")
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
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="السعر المفصل", default=0.00)

    def __str__(self):
        return f"{self.quantity} x {self.product.name}"


class RestaurantCard(models.Model):
    """
    بطاقة عرض للمطعم/المنتج تُنشأ تلقائياً عند إضافة منتج جديد.
    """
    product = models.OneToOneField(Product, on_delete=models.CASCADE, related_name='restaurant_card')
    display_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    image = models.CharField(max_length=500, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Card for {self.product.name}"
