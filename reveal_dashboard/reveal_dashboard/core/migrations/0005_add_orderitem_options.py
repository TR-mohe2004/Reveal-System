from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0004_add_order_payment_method'),
    ]

    operations = [
        migrations.AddField(
            model_name='orderitem',
            name='options',
            field=models.CharField(
                max_length=100,
                blank=True,
                default='',
                verbose_name='Order options',
            ),
        ),
    ]
