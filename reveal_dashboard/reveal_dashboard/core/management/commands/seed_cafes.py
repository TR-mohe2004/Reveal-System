from django.core.management.base import BaseCommand
from django.db import transaction

from core.models import Cafe
from users.models import User


CAFES = [
    {
        "name": "\u0645\u0642\u0647\u0649 \u0627\u0644\u0644\u063a\u0629 \u0627\u0644\u0639\u0631\u0628\u064a\u0629",
        "phone": "0911111111",
        "password": "12345678",
        "email": "cafe-0911111111@reveal.local",
    },
    {
        "name": "\u0645\u0642\u0647\u0649 \u0627\u0644\u0627\u0642\u062a\u0635\u0627\u062f",
        "phone": "0922222222",
        "password": "12345678",
        "email": "cafe-0922222222@reveal.local",
    },
    {
        "name": "\u0645\u0642\u0647\u0649 \u062a\u0642\u0646\u064a\u0629 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a",
        "phone": "0933333333",
        "password": "12345678",
        "email": "cafe-0933333333@reveal.local",
    },
]


class Command(BaseCommand):
    help = "Create cafe accounts and link them to cafes."

    def handle(self, *args, **options):
        for entry in CAFES:
            name = entry["name"]
            phone = entry["phone"]
            password = entry["password"]
            email = entry["email"]

            with transaction.atomic():
                user = User.objects.filter(phone_number=phone).first()
                if not user:
                    user = User.objects.filter(email=email).first()

                if not user:
                    user = User.objects.create_user(
                        email=email,
                        password=password,
                        full_name=name,
                        phone_number=phone,
                    )
                    self.stdout.write(self.style.SUCCESS(f"Created user for {name}"))
                else:
                    updated = False
                    if user.phone_number != phone:
                        user.phone_number = phone
                        updated = True
                    if user.full_name != name:
                        user.full_name = name
                        updated = True
                    if not user.check_password(password):
                        user.set_password(password)
                        updated = True
                    if updated:
                        user.save()
                        self.stdout.write(self.style.WARNING(f"Updated user for {name}"))

                cafe = Cafe.objects.filter(owner=user).first()
                if cafe:
                    updates = []
                    if cafe.name != name:
                        cafe.name = name
                        updates.append("name")
                    if not cafe.is_active:
                        cafe.is_active = True
                        updates.append("is_active")
                    if updates:
                        cafe.save(update_fields=updates)
                        self.stdout.write(self.style.WARNING(f"Updated cafe for {name}"))
                    continue

                cafe = Cafe.objects.filter(name=name).first()
                if cafe:
                    if cafe.owner is None:
                        cafe.owner = user
                        cafe.is_active = True
                        cafe.save(update_fields=["owner", "is_active"])
                        self.stdout.write(self.style.WARNING(f"Linked cafe {name} to user"))
                    else:
                        self.stdout.write(
                            self.style.WARNING(
                                f"Cafe {name} already linked to another user; no changes made."
                            )
                        )
                    continue

                cafe = Cafe.objects.create(name=name, owner=user, is_active=True)
                self.stdout.write(self.style.SUCCESS(f"Created cafe {name}"))

        self.stdout.write(self.style.SUCCESS("Cafe seeding complete."))
