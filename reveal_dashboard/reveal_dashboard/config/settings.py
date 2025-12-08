from pathlib import Path
import os
import firebase_admin
from firebase_admin import credentials

# تحديد المسار الأساسي للمشروع
BASE_DIR = Path(__file__).resolve().parent.parent

# مفتاح الأمان (يجب تغييره عند الرفع على استضافة حقيقية)
SECRET_KEY = 'django-insecure-your-secret-key-change-me'

# وضع التصحيح (True للتطوير، False للنشر)
DEBUG = True

# السماح لجميع الاستضافات (مفيد للتجربة مع فلاتر)
ALLOWED_HOSTS = ['*']

# --- التطبيقات المثبتة ---
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # --- مكتبات الطرف الثالث (لربط فلاتر) ---
    'rest_framework',  # لإنشاء الـ API
    'corsheaders',     # للسماح لتطبيق فلاتر بالاتصال بالسيرفر

    # --- تطبيقاتنا الخاصة ---
    'core.apps.CoreConfig',   # التطبيق الأساسي
    'users.apps.UsersConfig', # تطبيق المستخدمين (تم تفعيله الآن)
    'wallet.apps.WalletConfig', # تطبيق المحفظة (تم تفعيله الآن)
]

# --- الوسائط (Middleware) ---
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware', # يجب أن يكون في البداية
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
        'DIRS': [BASE_DIR / 'templates'], # مجلد القوالب الرئيسي
        'APP_DIRS': True, # البحث داخل مجلدات التطبيقات
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

# --- إعداد مودل المستخدم المخصص (مهم جداً) ---
# يخبر دجانغو باستخدام جدول المستخدمين الموجود في تطبيق users
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
STATIC_URL = 'static/'
STATICFILES_DIRS = [
    BASE_DIR / "static",
]
# أين سيجمع دجانغو الملفات عند النشر
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- إعدادات CORS (للسماح لتطبيق فلاتر بالاتصال) ---
CORS_ALLOW_ALL_ORIGINS = True # نسمح للجميع أثناء التطوير

# --- إعدادات REST Framework ---
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
}

# --- إعدادات Firebase ---
FIREBASE_CREDS_PATH = os.path.join(BASE_DIR, 'firebase-credentials.json')

# تهيئة Firebase Admin SDK (مرة واحدة فقط)
if not firebase_admin._apps:
    try:
        if os.path.exists(FIREBASE_CREDS_PATH):
            cred = credentials.Certificate(FIREBASE_CREDS_PATH)
            firebase_admin.initialize_app(cred, {
                'storageBucket': 'revealapp-8af3f.appspot.com'
            })
            print("✅ Firebase Admin SDK Initialized successfully!")
        else:
            print("⚠️ Warning: firebase-credentials.json not found.")
    except Exception as e:
        print(f"❌ CRITICAL: Error initializing Firebase Admin App: {e}")

# إعدادات Pyrebase (للاستخدام في الواجهات الأمامية للدجانغو إن لزم الأمر)
PYREBASE_CONFIG = {
    "apiKey": "AIzaSyCSCPWbtxmXJzTwGwj4OZDba3r3JaCuAlU",
    "authDomain": "revealapp-8af3f.firebaseapp.com",
    "projectId": "revealapp-8af3f",
    "storageBucket": "revealapp-8af3f.appspot.com",
    "messagingSenderId": "490797315957",
    "appId": "1:490797315957:web:1c88cd379ac1bc7274053c",
    "databaseURL": ""
}

# رابط تسجيل الدخول الافتراضي
LOGIN_URL = 'core:login'
LOGIN_REDIRECT_URL = '/' 
LOGOUT_REDIRECT_URL = '/login/'