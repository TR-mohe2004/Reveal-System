from .models import Cafe


def switchable_cafes(request):
    cafes = (
        Cafe.objects.filter(is_active=True, owner__isnull=False)
        .select_related('owner')
        .order_by('name')
    )
    return {'switchable_cafes': cafes}
