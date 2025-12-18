from rest_framework import serializers
from .models import Wallet, Transaction


class TransactionSerializer(serializers.ModelSerializer):
    college_name = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = ['id', 'wallet', 'amount', 'transaction_type', 'source', 'description', 'created_at', 'college_name']

    def get_college_name(self, obj):
        return getattr(obj.wallet, 'college', None)


class WalletSerializer(serializers.ModelSerializer):
    transactions = serializers.SerializerMethodField()

    class Meta:
        model = Wallet
        fields = ['id', 'user', 'balance', 'link_code', 'college', 'updated_at', 'transactions']

    def get_transactions(self, obj):
        txns = getattr(obj, 'prefetched_transactions', None) or obj.transactions.order_by('-created_at').select_related('wallet')
        return TransactionSerializer(txns, many=True).data
