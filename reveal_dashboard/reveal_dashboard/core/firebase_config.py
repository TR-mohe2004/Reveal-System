import firebase_admin
from firebase_admin import credentials, firestore
import os
from django.conf import settings

# تحديد المسار الجديد
cred_path = os.path.join(settings.BASE_DIR, 'config', 'serviceAccountKey.json')

# تهيئة المتغير بـ None لضمان عدم حدوث خطأ إذا فشل الاتصال
db = None

# محاولة تهيئة التطبيق إذا لم يكن مهيأً مسبقاً
if not firebase_admin._apps:
    try:
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print("✅ [Local] Firebase Connected Successfully!")
        else:
            print(f"⚠️ [Local Warning] File not found at: {cred_path}")
            print("⚠️ System running without Firebase connection.")
    except Exception as e:
        print(f"❌ [Local Error] Initializing Firebase: {e}")

# محاولة جلب العميل (Client) فقط إذا تم تهيئة التطبيق بنجاح
try:
    if firebase_admin._apps:
        db = firestore.client()
    else:
        db = None
except Exception as e:
    print(f"❌ Error getting Firestore client: {e}")
    db = None