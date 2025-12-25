from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0003_alter_category_options_cafe_is_active_product_rating_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='order',
            name='payment_method',
            field=models.CharField(
                max_length=10,
                choices=[('WALLET', '???????'), ('CASH', '???')],
                default='WALLET',
                verbose_name='????? ?????',
            ),
        ),
    ]
