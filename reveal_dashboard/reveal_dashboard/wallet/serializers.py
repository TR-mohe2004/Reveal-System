from rest_framework import serializers
from .models import Wallet, Transaction

class TransactionSerializer(serializers.ModelSerializer):
    # 1. تحسين العرض: إضافة التاريخ المنسق والنوع بالعربي
    created_at_formatted = serializers.SerializerMethodField()
    type_display = serializers.CharField(source='get_transaction_type_display', read_only=True)
    
    # 2. اسم الكلية/المقهى (كما طلبت)
    college_name = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = [
            'id', 
            'amount', 
            'transaction_type', 
            'type_display', 
            'source', 
            'description', 
            'created_at', 
            'created_at_formatted', 
            'college_name'
        ]

    def get_created_at_formatted(self, obj):
        # تنسيق: 2024-12-20 02:30 PM
        return obj.created_at.strftime("%Y-%m-%d %I:%M %p")

    def get_college_name(self, obj):
        # محاولة ذكية لجلب اسم الكلية/المقهى
        # أولاً: نحاول جلبه من المحفظة مباشرة إذا كان الحقل موجوداً
        if hasattr(obj.wallet, 'college') and obj.wallet.college:
            return str(obj.wallet.college)
        
        # ثانياً: إذا لم نجد، نحاول جلبه من وصف المعاملة (إذا كان الشراء من مقهى معين)
        # هذا يعتمد على كيفية تخزين الوصف، لكنه احتياط جيد
        return "غير محدد"


class WalletSerializer(serializers.ModelSerializer):
    # نعرض آخر 10 معاملات فقط لتسريع التطبيق (بدلاً من جلب الآلاف)
    recent_transactions = serializers.SerializerMethodField()
    currency = serializers.SerializerMethodField()

    class Meta:
        model = Wallet
        fields = ['id', 'balance', 'currency', 'link_code', 'updated_at', 'recent_transactions']

    def get_currency(self, obj):
        return "LYD"

    def get_recent_transactions(self, obj):
        # جلب أحدث 10 عمليات فقط
        qs = Transaction.objects.filter(wallet=obj).order_by('-created_at')[:10]
        return TransactionSerializer(qs, many=True).data