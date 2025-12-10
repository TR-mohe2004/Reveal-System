from django.db import models
from django.conf import settings
import uuid

class Wallet(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='wallet', verbose_name="الطالب")
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="الرصيد الحالي")
    link_code = models.CharField(max_length=20, unique=True, blank=True, null=True, verbose_name="كود الربط")
    college = models.CharField(max_length=100, default="كلية تقنية المعلومات", verbose_name="الكلية")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="آخر تحديث")

    def save(self, *args, **kwargs):
        # توليد كود الربط تلقائياً إذا لم يكن موجوداً
        if not self.link_code:
            self.link_code = str(uuid.uuid4())[:8].upper()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"محفظة: {self.user} | {self.balance}"

class Transaction(models.Model):
    TRANSACTION_TYPES = (
        ('DEPOSIT', 'إيداع (شحن)'),
        ('WITHDRAWAL', 'خصم (دفع)'),
    )
    SOURCES = (
        ('SYSTEM', 'المنظومة'), 
        ('APP', 'التطبيق'),   
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="القيمة")
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    source = models.CharField(max_length=20, choices=SOURCES, default='SYSTEM')
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.pk: 
            if self.transaction_type == 'DEPOSIT':
                self.wallet.balance += self.amount
            elif self.transaction_type == 'WITHDRAWAL':
                # السماح بالخصم فقط إذا كان الرصيد كافياً
                if self.wallet.balance >= self.amount:
                    self.wallet.balance -= self.amount
                else:
                    raise ValueError("الرصيد لا يكفي!")
            self.wallet.save()
        super().save(*args, **kwargs)