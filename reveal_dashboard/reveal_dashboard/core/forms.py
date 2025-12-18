from django import forms
from .models import Product


class ProductForm(forms.ModelForm):
    class Meta:
        model = Product
        fields = ['name', 'category', 'price', 'description', 'image', 'is_available']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'اسم المنتج'}),
            'category': forms.Select(attrs={'class': 'form-select'}),
            'price': forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'السعر'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'وصف المنتج'}),
            'image': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'مسار الصورة'}),
            'is_available': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Make optional; view will backfill smart defaults when missing.
        self.fields['category'].required = False
        self.fields['image'].required = False
