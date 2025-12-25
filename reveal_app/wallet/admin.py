from django.contrib import admin
from .models import Wallet, Transaction

@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ('user', 'balance', 'college', 'link_code', 'updated_at')
    search_fields = ('user__full_name', 'user__phone_number', 'user__email', 'link_code')
    list_filter = ('college', 'updated_at')
    ordering = ('-updated_at',)
    
    # نجعل كود الربط للقراءة فقط لأنه يولد تلقائياً
    readonly_fields = ('link_code', 'updated_at')

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('id', 'wallet_user', 'amount', 'transaction_type', 'source', 'created_at')
    list_filter = ('transaction_type', 'source', 'created_at')
    search_fields = ('wallet__user__full_name', 'wallet__user__phone_number', 'description', 'id')
    ordering = ('-created_at',)

    # دالة مساعدة لعرض اسم المستخدم في قائمة المعاملات
    def wallet_user(self, obj):
        return obj.wallet.user.full_name
    wallet_user.short_description = 'الطالب'

    # 🔒 حماية أمنية هامة:
    # نمنع تعديل المعاملة المالية بعد إنشائها للحفاظ على مصداقية البيانات
    def has_change_permission(self, request, obj=None):
        return False

    # يمكن السماح بالحذف (للمدير فقط) أو منعه أيضاً حسب رغبتك
    # def has_delete_permission(self, request, obj=None):
    #     return False