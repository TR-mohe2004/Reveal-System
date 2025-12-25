from firebase_admin import firestore


def execute_purchase_transaction(db, user_phone: str, total_price: float, items: list):
    """
    Execute an atomic purchase:
    - Lock wallet doc by phone.
    - Validate balance >= total_price.
    - Deduct and log transaction.
    """
    user_ref = db.collection('users').document(user_phone)
    tx_ref = db.collection('transactions').document()

    @firestore.transactional
    def _txn(transaction):
        snapshot = user_ref.get(transaction=transaction)
        if not snapshot.exists:
            raise ValueError("CODE_4002: user not found")

        data = snapshot.to_dict() or {}
        balance = float(data.get('balance', 0))
        if balance < total_price:
            raise ValueError("CODE_4001: insufficient funds")

        new_balance = balance - total_price
        transaction.update(user_ref, {
            'balance': new_balance,
            'last_transaction': tx_ref
        })
        transaction.set(tx_ref, {
            'transaction_id': tx_ref.id,
            'user_phone': user_phone,
            'amount': total_price,
            'type': 'purchase',
            'status': 'success',
            'items': items,
            'timestamp': firestore.SERVER_TIMESTAMP,
        })
        return new_balance

    transaction = db.transaction()
    return _txn(transaction)
