from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='secondary_phone_number',
            field=models.CharField(
                max_length=15,
                unique=True,
                blank=True,
                null=True,
                verbose_name='رقم هاتف إضافي',
            ),
        ),
    ]
