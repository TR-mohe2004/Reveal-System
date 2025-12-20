from pathlib import Path
import os
from decouple import config
import firebase_admin
from firebase_admin import credentials, firestore

# --- تحديد المسار الأساسي للمشروع ---
BASE_DIR = Path(__file__).resolve().parent.parent

# --- إعدادات الأمان ---
# يفضل استخدام متغيرات البيئة، ولكن وضعنا قيم افتراضية لضمان عدم توقف الموقع
SECRET_KEY = config('DJANGO_SECRET_KEY', default='django-insecure-change-me-please')

# اجعلها True أثناء التطوير، و False عند النشر النهائي
DEBUG = config('DJANGO_DEBUG', default=True, cast=bool)

# السماح لجميع النطاقات مؤقتاً (بما في ذلك PythonAnywhere)
ALLOWED_HOSTS = ['*'] 

# --- التطبيقات المثبتة ---
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # --- مكتبات الطرف الثالث ---
    'rest_framework',
    'rest_framework.authtoken', # لإنشاء التوكن للموبايل
    'corsheaders', # للسماح للموبايل بالاتصال

    # --- تطبيقاتنا الخاصة ---
    'core.apps.CoreConfig',
    'users.apps.UsersConfig',
    'wallet.apps.WalletConfig',
    # تأكد أن لديك تطبيق products إذا كنت تستخدمه، أضفه هنا:
    # 'products.apps.ProductsConfig', 
]

# --- الوسائط (Middleware) ---
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware', # ✅ مكانه صحيح (الأول)
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

# --- القوالب (Templates) ---
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# --- قاعدة البيانات ---
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# --- إعداد مودل المستخدم المخصص ---
AUTH_USER_MODEL = 'users.User'

# --- مدققات كلمة المرور ---
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# --- إعدادات اللغة والوقت ---
LANGUAGE_CODE = 'ar'
TIME_ZONE = 'Africa/Tripoli'
USE_I18N = True
USE_TZ = True

# --- الملفات الثابتة (Static & Media) ---
STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / "static"]
STATIC_ROOT = BASE_DIR / "staticfiles" 

# إعدادات الصور والملفات المرفوعة
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- إعدادات CORS (للموبايل) ---
CORS_ALLOW_ALL_ORIGINS = True # السماح للجميع (مهم للـ Flutter)
CORS_ALLOW_CREDENTIALS = True

# --- إعدادات REST Framework ---
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny', # يسمح بالوصول العام، يمكنك تغييره لاحقاً
    ],
}

# --- التخزين المؤقت (تعديل هام جداً للسيرفر) ---
# ❌ تم إيقاف Redis لأنه يسبب مشاكل في PythonAnywhere
# ✅ تم استبداله بـ Local Memory Cache (الأفضل والاسرع حالياً)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}

# --- إعدادات Firebase ---
#  محاولة قراءة المسار من المتغيرات، أو استخدام المسار الافتراضي
FIREBASE_CREDS_PATH = config('FIREBASE_CREDENTIALS_PATH', default=str(BASE_DIR / 'config' / 'serviceAccountKey.json'))

# تهيئة الفايربيز مع حماية من الأخطاء
if not firebase_admin._apps:
    try:
        if os.path.exists(FIREBASE_CREDS_PATH):
            cred = credentials.Certificate(FIREBASE_CREDS_PATH)
            firebase_admin.initialize_app(cred)
            print("✅ [OK] Firebase Admin SDK Initialized successfully!")
        else:
            # رسالة تحذير فقط لكي لا يتوقف السيرفر بالكامل
            print(f"⚠️ [Warning] Firebase JSON file not found at: {FIREBASE_CREDS_PATH}")
            print("   Make sure the file exists inside the 'config' folder.")
    except Exception as e:
        print(f"❌ [Error] Failed to initialize Firebase: {e}")

# تعريف العميل (سيكون None إذا فشل الاتصال، وهذا يمنع انهيار الموقع)
FIRESTORE_DB = firestore.client() if firebase_admin._apps else None

# إعدادات Pyrebase (للواجهة الأمامية أو استخدامات خاصة)
PYREBASE_CONFIG = {
    "apiKey": "AIzaSyCSCPWbtxmXJzTwGwj4OZDba3r3JaCuAlU",
    "authDomain": "revealapp-8af3f.firebaseapp.com",
    "projectId": "revealapp-8af3f",
    "storageBucket": "revealapp-8af3f.appspot.com",
    "messagingSenderId": "490797315957",
    "appId": "1:490797315957:web:1c88cd379ac1bc7274053c",
    "databaseURL": ""
}

# --- توجيهات تسجيل الدخول ---
LOGIN_URL = 'core:login'
LOGIN_REDIRECT_URL = 'core:dashboard'
LOGOUT_REDIRECT_URL = 'core:login'