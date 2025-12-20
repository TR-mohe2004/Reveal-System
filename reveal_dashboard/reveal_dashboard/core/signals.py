from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Order
from .utils import send_real_notification

@receiver(post_save, sender=Order)
def order_status_notification(sender, instance, created, **kwargs):
    """
    إرسال إشعار تلقائي للمستخدم عند تغير حالة الطلب.
    """
    if created:
        # إشعار عند إنشاء الطلب لأول مرة (اختياري)
        return

    # إرسال إشعار حسب الحالة الجديدة
    if instance.status == 'PREPARING':
        send_real_notification(
            instance.user, 
            "جاري التحضير 👨‍🍳", 
            f"بدأنا في تحضير طلبك #{instance.order_number}. يرجى الانتظار."
        )
    
    elif instance.status == 'READY':
        send_real_notification(
            instance.user, 
            "طلبك جاهز! 🍕", 
            f"الطلب #{instance.order_number} جاهز للاستلام. صحتين!"
        )

    elif instance.status == 'COMPLETED':
        send_real_notification(
            instance.user, 
            "تم الاستلام ✅", 
            f"تم تسليم الطلب #{instance.order_number}. شكراً لاستخدامك تطبيقنا."
        )

    elif instance.status == 'CANCELLED':
        send_real_notification(
            instance.user, 
            "تم إلغاء الطلب ❌", 
            f"عذراً، تم إلغاء الطلب #{instance.order_number}. يرجى مراجعة الإدارة."
        )