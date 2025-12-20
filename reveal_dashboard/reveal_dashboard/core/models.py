from django.db import models
from django.conf import settings
import uuid

class Cafe(models.Model):
    name = models.CharField(max_length=100, verbose_name="اسم الكلية/المقهى")
    # ✅ تغيير الصورة لرفع ملفات بدلاً من نصوص
    image = models.ImageField(upload_to='cafes/', blank=True, null=True, verbose_name="شعار الكلية")
    location = models.CharField(max_length=200, blank=True, null=True, verbose_name="الموقع")
    # ✅ حقل لتفعيل أو تعطيل الكلية مؤقتاً
    is_active = models.BooleanField(default=True, verbose_name="مفعل")
    
    owner = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='my_cafe',
        verbose_name="مسؤول الكلية",
        null=True, blank=True # لكي لا يسبب مشاكل عند الإنشاء
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Category(models.Model):
    name = models.CharField(max_length=100, verbose_name="اسم التصنيف")

    class Meta:
        verbose_name = "تصنيف"
        verbose_name_plural = "التصنيفات"

    def __str__(self):
        return self.name

class Product(models.Model):
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='products', verbose_name="الكلية")
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products', verbose_name="الفئة")
    name = models.CharField(max_length=100, verbose_name="اسم المنتج")
    description = models.TextField(verbose_name="الوصف", blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="السعر")
    
    # ✅ رفع الصورة لمجلد المنتجات
    image = models.ImageField(upload_to='products/', blank=True, null=True, verbose_name="صورة المنتج")
    
    is_available = models.BooleanField(default=True, verbose_name="متاح")
    
    # ✅ إضافات لتوافق مع التطبيق (التقييم)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=4.5, verbose_name="التقييم")
    rating_count = models.IntegerField(default=10, verbose_name="عدد المقيمين")

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name
    
    # دالة مساعدة لجلب رابط الصورة، إذا لم توجد تعيد قيمة فارغة
    @property
    def image_url(self):
        if self.image:
            return self.image.url
        return ""

class Order(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'قيد الانتظار'),
        ('PREPARING', 'قيد التحضير'),
        ('READY', 'جاهز للاستلام'),
        ('COMPLETED', 'مكتمل'),
        ('CANCELLED', 'ملغى'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='orders', verbose_name="العميل")
    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name='orders', verbose_name="الكلية")
    total_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="الإجمالي")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', verbose_name="الحالة")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاريخ الطلب")
    order_number = models.CharField(max_length=10, unique=True, blank=True, null=True, verbose_name="رقم الطلب")

    def save(self, *args, **kwargs):
        if not self.order_number:
            # توليد رقم طلب قصير وفريد
            self.order_number = str(uuid.uuid4().int)[:8]
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Order #{self.order_number} - {self.user}"

class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1, verbose_name="الكمية")
    price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="سعر الوحدة عند الطلب", default=0.00)

    def __str__(self):
        return f"{self.quantity} x {self.product.name}"