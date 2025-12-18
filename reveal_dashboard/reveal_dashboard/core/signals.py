from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Product, RestaurantCard # تأكد من اسم الموديل الخاص بكرت المطعم
from .utils import get_smart_image_for_product

@receiver(post_save, sender=Product)
def create_restaurant_card_automatically(sender, instance, created, **kwargs):
    """
    عندما يضيف صاحب المطعم منتجاً جديداً:
    1. النظام ينشئ كرت مطعم تلقائياً.
    2. النظام يفحص الاسم ويضع الصورة المناسبة إذا لم يرفعها الادمن.
    """
    if created:
        # تحديد الصورة الذكية إذا لم توجد صورة
        if not instance.image:
            instance.image = get_smart_image_for_product(instance.name)
            instance.save()
        
        # إنشاء كرت المطعم للعرض في التطبيق
        RestaurantCard.objects.create(
            product=instance,
            is_active=True,
            display_price=instance.price,
            image=instance.image
        )
