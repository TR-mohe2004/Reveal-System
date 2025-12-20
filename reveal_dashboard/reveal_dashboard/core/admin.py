from django.contrib import admin
from .models import Cafe, Category, Product, Order, OrderItem

# --- دالة مساعدة: جلب الكلية الخاصة بالمستخدم الحالي ---
def get_owner_cafe(user):
    """
    تعيد الكلية المرتبطة بالمستخدم إذا كان مدير كلية.
    وتعيد None إذا كان سوبر يوزر (لأنه يرى الكل).
    """
    if user.is_superuser:
        return None
    try:
        return user.my_cafe  # نعتمد على related_name='my_cafe' في المودل
    except AttributeError:
        return None

# --- 1. إدارة الكليات (المقاهي) ---
@admin.register(Cafe)
class CafeAdmin(admin.ModelAdmin):
    list_display = ('name', 'location', 'is_active', 'owner')
    search_fields = ('name',)
    list_filter = ('is_active',) 
    
    # تحديد الحقول التي تظهر في النموذج
    fields = ('name', 'image', 'location', 'is_active', 'owner')

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        # السوبر يوزر يرى كل الكليات (تقنية اقتصاد عربية..)
        if request.user.is_superuser:
            return qs
        # مدير الكلية يرى فقط كليته الخاصة ليعدل بياناتها
        return qs.filter(owner=request.user)

# --- 2. إدارة التصنيفات ---
@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name',)

# --- 3. إدارة المنتجات ---
@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'is_available', 'cafe_name', 'created_at')
    list_filter = ('is_available', 'category')
    search_fields = ('name', 'description')
    list_editable = ('is_available', 'price')

    def cafe_name(self, obj):
        return obj.cafe.name
    cafe_name.short_description = "الكلية"

    # --- الفلترة: عرض منتجات الكلية الخاصة بالمستخدم فقط ---
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(cafe__owner=request.user)

    # --- الحفظ: ربط المنتج بكلية المستخدم تلقائيا ---
    def save_model(self, request, obj, form, change):
        if not request.user.is_superuser:
            my_cafe = get_owner_cafe(request.user)
            if my_cafe:
                obj.cafe = my_cafe
        super().save_model(request, obj, form, change)

    # --- النموذج: إخفاء حقل اختيار الكلية لمدراء الكليات ---
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        if not request.user.is_superuser:
            # نخفي حقل الكلية لأننا سنحدده تلقائيا في الخلفية
            if 'cafe' in form.base_fields:
                form.base_fields['cafe'].disabled = True
                form.base_fields['cafe'].required = False
        return form

# --- تفاصيل العناصر داخل الطلب ---
class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('product', 'quantity', 'price')
    can_delete = False

# --- 4. إدارة الطلبات ---
@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('order_number', 'user_info', 'total_price', 'status', 'cafe', 'created_at')
    list_filter = ('status', 'created_at') # حذفنا فلتر الكلية للمستخدم العادي لأنه يرى كليته فقط
    search_fields = ('order_number', 'user__phone_number', 'user__full_name')
    ordering = ('-created_at',)
    inlines = [OrderItemInline]
    
    readonly_fields = ('total_price', 'user', 'cafe', 'created_at')

    def user_info(self, obj):
        return f"{obj.user.full_name} ({obj.user.phone_number})"
    user_info.short_description = "العميل"

    # --- الفلترة: عرض طلبات الكلية الخاصة بالمستخدم فقط ---
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(cafe__owner=request.user)
