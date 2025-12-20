import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import os
import re

# 1. التحقق من حالة Firebase (نعتمد على التهيئة التي تمت في settings.py)
def is_firebase_ready():
    return bool(firebase_admin._apps)

def send_real_notification(user, title, body):
    """
    دالة لإرسال إشعار حقيقي لهاتف المستخدم عبر FCM
    """
    # 1. التأكد من أن الفايربيز يعمل
    if not is_firebase_ready():
        print("⚠️ Firebase is not initialized. Notification skipped.")
        return

    # 2. التأكد أن المستخدم لديه توكن (FCM Token)
    # ملاحظة: يجب أن يكون في مودل المستخدم حقل اسمه fcm_token
    if not hasattr(user, 'fcm_token') or not user.fcm_token:
        # يمكن طباعة تحذير للتجربة (اختياري)
        # print(f"User {user} has no FCM Token.")
        return
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=user.fcm_token,
        )
        response = messaging.send(message)
        return response
    except Exception as e:
        print(f"❌ Error sending notification to {user}: {e}")

def get_smart_image_for_product(product_name):
    """
    تحدد مسار صورة افتراضية بناءً على اسم المنتج.
    تنبيه: تأكد أن هذه الصور موجودة فعلاً في مجلد media/products/defaults/
    """
    # نستخدم مساراً نسبياً يتناسب مع ImageField
    base_path = 'products/defaults/'

    if not product_name:
        return None # نرجع None لكي لا نضع مساراً خاطئاً
        
    name_lower = product_name.lower()
    has = lambda *words: any(word in name_lower for word in words)
    
    image_name = 'general.jpg'

    # Scenario A: Pizza
    if has('pizza', 'بيتزا'):
        image_name = 'pizza.jpg'
    # Scenario B: Burgers
    elif has('burger', 'cheeseburger', 'برجر'):
        image_name = 'burger.jpg'
    # Scenario C: Drinks
    elif has('cola', 'pepsi', 'soda', 'drink', 'juice', 'coffee', 'مشروب', 'قهوة', 'عصير'):
        image_name = 'juice.jpg'
    # Scenario D: Desserts
    elif has('cake', 'sweet', 'dessert', 'kunafa', 'حلى', 'كيك', 'كنافة'):
        image_name = 'dessert.jpg'
    
    # نرجع المسار كاملاً
    return f'{base_path}{image_name}'

def normalize_libyan_phone(raw_phone):
    """
    توحيد صيغة الرقم الليبي ليصبح 09XXXXXXXX
    """
    if not raw_phone:
        return ""
    
    # إزالة أي حروف أو مسافات
    digits = re.sub(r'\D', '', str(raw_phone))
    
    # معالجة كود الدولة (218)
    if digits.startswith('218'):
        digits = digits[3:]
    
    # التأكد من الطول (الرقم الليبي عادة 9 أرقام بدون الصفر، أو 10 مع الصفر)
    if len(digits) == 9:
        digits = '0' + digits
        
    return digits