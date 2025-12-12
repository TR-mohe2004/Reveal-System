from django.contrib import admin
from .models import Cafe, Category, Product, Order, OrderItem

@admin.register(Cafe)
class CafeAdmin(admin.ModelAdmin):
    list_display = ('name', 'location', 'created_at')
    search_fields = ('name',)

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name',)

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'cafe', 'category', 'price', 'is_available')
    list_filter = ('cafe', 'category', 'is_available')
    search_fields = ('name',)

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('order_number', 'user', 'cafe', 'total_price', 'status', 'created_at')
    list_filter = ('status', 'cafe', 'created_at')
    search_fields = ('order_number', 'user__full_name')
