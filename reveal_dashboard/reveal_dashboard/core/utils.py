import firebase_admin
from firebase_admin import credentials, messaging
import os
import re

# 1. إعداد نظام الإشعارات
try:
    if not firebase_admin._apps:
        # تأكد أن ملف serviceAccountKey.json موجود بجانب ملف manage.py
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    FIREBASE_READY = True
except Exception as e:
    print(f"Warning: Firebase not initialized. Error: {e}")
    FIREBASE_READY = False

def send_real_notification(user, title, body):
    """
    دالة لإرسال إشعار حقيقي لهاتف المستخدم
    """
    # نتأكد أن Firebase يعمل وأن المستخدم لديه توكن
    if not FIREBASE_READY or not hasattr(user, 'fcm_token') or not user.fcm_token:
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
        print(f"Error sending notification: {e}")

def get_smart_image_for_product(product_name):
    """
    تحدد الصورة بناءً على اسم المنتج
    """
    base_path = 'products/defaults/'

    if not product_name:
        return f'{base_path}general.jpg'
        
    name_lower = product_name.lower()
    has = lambda *words: any(word in name_lower for word in words)
    
    # Scenario A: Pizza-like items
    if has('pizza'):
        return f'{base_path}pizza.jpg'
    # Scenario B: Burgers
    if has('burger', 'cheeseburger', 'cheese burger'):
        return f'{base_path}burger.jpg'
    # Scenario C: Drinks (cola/pepsi/juice)
    if has('cola', 'pepsi', 'soda', 'drink', 'juice'):
        return f'{base_path}juice.jpg'
    # Scenario D: Desserts / sweets
    if has('cheesecake', 'cheese cake', 'kunafa', 'knafa', 'dessert', 'cake', 'sweet'):
        return f'{base_path}dessert.jpg'
    
    return f'{base_path}general.jpg'

def normalize_libyan_phone(raw_phone):
    """
    توحيد صيغة الرقم الليبي
    """
    if not raw_phone:
        return ""
    # إزالة أي حروف أو رموز
    digits = re.sub(r'\D', '', str(raw_phone))
    
    # معالجة كود الدولة
    if digits.startswith('218'):
        digits = digits[3:]
    
    # إضافة الصفر في البداية إذا كان ناقصاً
    if digits.startswith('9'):
        digits = '0' + digits
        
    return digits
