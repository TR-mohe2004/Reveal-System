from django.contrib import admin
from .models import Wallet, Transaction

class TransactionInline(admin.TabularInline):
    model = Transaction
    extra = 0
    readonly_fields = ('created_at',)
    can_delete = False

@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    # تم التصحيح: استخدام updated_at بدلاً من last_update
    list_display = ('user', 'balance', 'updated_at')
    # تم التحديث للبحث برقم الهاتف والاسم
    search_fields = ('user__phone_number', 'user__full_name')
    inlines = [TransactionInline]

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('wallet', 'transaction_type', 'amount', 'source', 'created_at')
    list_filter = ('transaction_type', 'source', 'created_at')
