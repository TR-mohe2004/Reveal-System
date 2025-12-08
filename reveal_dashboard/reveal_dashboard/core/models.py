from django.db import models
from django.conf import settings

# 1. المقاهي
class Cafe(models.Model):
    name = models.CharField(max_length=100, verbose_name="اسم المقهى")
    image = models.CharField(max_length=500, blank=True, null=True, verbose_name="رابط الصورة")
    location = models.CharField(max_length=200, blank=True, null=True, verbose_name="الموقع")
    owner = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='owned_cafe', verbose_name="مالك المقهى")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

# 2. التصنيفات
class Category(models.Model):
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='categories', verbose_name="المقهى")
    name = models.CharField(max_length=100, verbose_name="اسم التصنيف")
    
    def __str__(self):
        return f"{self.name} ({self.cafe.name})"

# 3. المنتجات (البضاعة)
class Product(models.Model):
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='products', verbose_name="المقهى")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products', verbose_name="التصنيف")
    name = models.CharField(max_length=100, verbose_name="اسم المنتج")
    description = models.TextField(verbose_name="الوصف", blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="السعر")
    image = models.CharField(max_length=500, verbose_name="رابط الصورة")
    is_available = models.BooleanField(default=True, verbose_name="متاح للطلب؟")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

# 4. الطلبات (التي تأتي من التطبيق)
class Order(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'قيد الانتظار'),
        ('PREPARING', 'قيد التجهيز'),
        ('READY', 'جاهز للاستلام'),
        ('COMPLETED', 'تم الاستلام'),
        ('CANCELLED', 'ملغي'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='orders', verbose_name="الطالب")
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='orders', verbose_name="المقهى")
    total_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="الإجمالي")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', verbose_name="حالة الطلب")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="وقت الطلب")
    order_number = models.CharField(max_length=10, unique=True, verbose_name="رقم الطلب") # سنولده تلقائياً

    def __str__(self):
        return f"طلب #{self.order_number} - {self.user.full_name}"

# 5. تفاصيل الطلب (ماذا يحتوي؟)
class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1, verbose_name="الكمية")
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="سعر القطعة وقت الطلب")

    def __str__(self):
        return f"{self.quantity} x {self.product.name}"
