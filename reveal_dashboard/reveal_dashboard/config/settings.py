from pathlib import Path
import os
import firebase_admin
from firebase_admin import credentials

# تحديد المسار الأساسي للمشروع
BASE_DIR = Path(__file__).resolve().parent.parent

# --- إعدادات الأمان (مهمة للاستضافة) ---

# مفتاح الأمان: يفضل تغييره بمتغير بيئة عند النشر النهائي، لكن لا بأس به الآن
SECRET_KEY = 'django-insecure-your-secret-key-change-me'

# وضع التصحيح: نجعله True للتطوير، ويمكن تغييره لـ False عند النشر النهائي لإخفاء الأخطاء عن المستخدمين
DEBUG = True

# السماح لجميع الاستضافات (الآن يقبل Localhost و PythonAnywhere وأي دومين)
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
    'rest_framework',  # لإنشاء الـ API
    'rest_framework.authtoken', # مهم جداً: لإدارة التوكنات (Login/Signup)
    'corsheaders',     # للسماح لتطبيق فلاتر بالاتصال

    # --- تطبيقاتنا الخاصة ---
    'core.apps.CoreConfig',   
    'users.apps.UsersConfig', 
    'wallet.apps.WalletConfig', 
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
# هذه الإعدادات ضرورية جداً لظهور الصور والتنسيقات في الاستضافة

STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / "static"]
# هذا المسار الذي ستستخدمه الاستضافة لتجميع الملفات (أمر collectstatic)
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- إعدادات CORS (للسماح لتطبيق فلاتر بالاتصال) ---
CORS_ALLOW_ALL_ORIGINS = True 
CORS_ALLOW_CREDENTIALS = True

# --- إعدادات REST Framework ---
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication', # للتطبيق (موبايل)
        'rest_framework.authentication.SessionAuthentication', # للمتصفح (Dashboard)
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny', # افتراضياً مسموح للكل (يمكن تقييده في Views)
    ],
}

# --- إعدادات Firebase ---
# استخدام مسار مرن يعمل على ويندوز ولينكس (الاستضافة)
FIREBASE_CREDS_PATH = BASE_DIR / 'firebase-credentials.json'

# تهيئة Firebase Admin SDK
if not firebase_admin._apps:
    try:
        if os.path.exists(FIREBASE_CREDS_PATH):
            cred = credentials.Certificate(str(FIREBASE_CREDS_PATH))
            firebase_admin.initialize_app(cred, {
                'storageBucket': 'revealapp-8af3f.appspot.com'
            })
            print("[OK] Firebase Admin SDK Initialized successfully!")
        else:
            # رسالة تحذيرية في الكونسول إذا لم يجد الملف
            print(f"⚠️ Warning: firebase-credentials.json not found at {FIREBASE_CREDS_PATH}")
    except Exception as e:
        print(f"[X] Error initializing Firebase: {e}")

# إعدادات Pyrebase (للواجهة الأمامية إن لزمت)
PYREBASE_CONFIG = {
    "apiKey": "AIzaSyCSCPWbtxmXJzTwGwj4OZDba3r3JaCuAlU",
    "authDomain": "revealapp-8af3f.firebaseapp.com",
    "projectId": "revealapp-8af3f",
    "storageBucket": "revealapp-8af3f.appspot.com",
    "messagingSenderId": "490797315957",
    "appId": "1:490797315957:web:1c88cd379ac1bc7274053c",
    "databaseURL": ""
}

# توجيهات تسجيل الدخول
LOGIN_URL = 'core:login'
LOGIN_REDIRECT_URL = 'core:dashboard' # تم التعديل ليوجه للداشبورد مباشرة
LOGOUT_REDIRECT_URL = 'core:login'