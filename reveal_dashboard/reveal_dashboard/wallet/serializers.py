from rest_framework import serializers
from .models import Wallet, Transaction

class TransactionSerializer(serializers.ModelSerializer):
    # إضافة اسم الكلية لتظهر في سجل المعاملات في التطبيق
    college_name = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = ['id', 'amount', 'transaction_type', 'source', 'description', 'created_at', 'college_name']

    def get_college_name(self, obj):
        return getattr(obj.wallet, 'college', None)


class WalletSerializer(serializers.ModelSerializer):
    # عرض المعاملات كجزء من المحفظة (اختياري، لكن مفيد للتطبيق)
    transactions = TransactionSerializer(many=True, read_only=True)
    currency = serializers.SerializerMethodField()

    class Meta:
        model = Wallet
        fields = ['id', 'balance', 'currency', 'link_code', 'college', 'updated_at', 'transactions']

    def get_currency(self, obj):
        return "LYD"