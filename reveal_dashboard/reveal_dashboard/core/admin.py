from django.contrib import admin
from .models import Cafe, Category, Product

@admin.register(Cafe)
class CafeAdmin(admin.ModelAdmin):
    list_display = ('name', 'location', 'created_at')
    search_fields = ('name',)

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'cafe')
    list_filter = ('cafe',)

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'cafe', 'category', 'price', 'is_available')
    list_filter = ('cafe', 'category', 'is_available')
    search_fields = ('name',)
