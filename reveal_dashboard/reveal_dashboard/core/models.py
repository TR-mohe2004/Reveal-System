from django.conf import settings
from django.db import models
import uuid


class Cafe(models.Model):
    name = models.CharField(max_length=100, verbose_name="اسم المقهى")
    image = models.ImageField(upload_to='cafes/', blank=True, null=True, verbose_name="صورة المقهى")
    location = models.CharField(max_length=200, blank=True, null=True, verbose_name="الموقع")
    is_active = models.BooleanField(default=True, verbose_name="نشط")
    owner = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='my_cafe',
        verbose_name="مدير المقهى",
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Category(models.Model):
    name = models.CharField(max_length=100, verbose_name="الفئة")

    class Meta:
        verbose_name = "فئة"
        verbose_name_plural = "الفئات"

    def __str__(self):
        return self.name


class Product(models.Model):
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='products', verbose_name="المقهى")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products', verbose_name="الفئة")
    name = models.CharField(max_length=100, verbose_name="اسم المنتج")
    description = models.TextField(verbose_name="الوصف", blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="السعر")
    image = models.ImageField(upload_to='products/', blank=True, null=True, verbose_name="صورة المنتج")
    is_available = models.BooleanField(default=True, verbose_name="متاح")
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=4.5, verbose_name="التقييم")
    rating_count = models.IntegerField(default=10, verbose_name="عدد التقييمات")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    @property
    def image_url(self):
        if self.image:
            return self.image.url
        return ""


class Order(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'قيد الانتظار'),
        ('ACCEPTED', 'تم قبول الطلب'),
        ('PREPARING', 'قيد التحضير'),
        ('READY', 'جاهز للاستلام'),
        ('COMPLETED', 'مكتمل'),
        ('CANCELLED', 'ملغي'),
    )

    PAYMENT_METHOD_CHOICES = (
        ('WALLET', 'المحفظة'),
        ('CASH', 'نقداً'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='orders', verbose_name="المستخدم")
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='orders', verbose_name="المقهى")
    total_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="الإجمالي")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', verbose_name="الحالة")
    payment_method = models.CharField(max_length=10, choices=PAYMENT_METHOD_CHOICES, default='WALLET', verbose_name='طريقة الدفع')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاريخ الطلب")
    order_number = models.CharField(max_length=10, unique=True, blank=True, null=True, verbose_name="رقم الطلب")

    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = str(uuid.uuid4().int)[:8]
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Order #{self.order_number} - {self.user}"


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1, verbose_name="الكمية")
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="سعر الوحدة", default=0.00)
    options = models.CharField(max_length=100, blank=True, default='', verbose_name='تفاصيل إضافية')

    def __str__(self):
        return f"{self.quantity} x {self.product.name}"


class SystemSettings(models.Model):
    system_name = models.CharField(max_length=200, default='منظومة ريفيل', verbose_name='اسم النظام')
    welcome_message = models.CharField(max_length=255, default='مرحباً بك', verbose_name='رسالة الترحيب')
    min_charge_amount = models.DecimalField(max_digits=10, decimal_places=2, default=1.00, verbose_name='الحد الأدنى للشحن')
    currency_symbol = models.CharField(max_length=10, default='د.ل', verbose_name='رمز العملة')
    allow_registration = models.BooleanField(default=True, verbose_name='السماح بالتسجيل')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='آخر تحديث')

    def __str__(self):
        return "إعدادات النظام"

    @classmethod
    def get_solo(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


class InventoryItem(models.Model):
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='inventory_items', verbose_name='المقهى')
    name = models.CharField(max_length=150, verbose_name='اسم الصنف')
    unit = models.CharField(max_length=50, blank=True, default='', verbose_name='الوحدة')
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name='الكمية')
    min_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name='الحد الأدنى')
    notes = models.TextField(blank=True, default='', verbose_name='ملاحظات')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='آخر تحديث')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاريخ الإضافة')

    def __str__(self):
        return f"{self.name} ({self.cafe})"
