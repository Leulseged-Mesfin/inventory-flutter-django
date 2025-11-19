from django.core.management.base import BaseCommand
from inventory.models import Order, Product, CustomerInfo
from inventory.serializers import OrderSerializer
from rest_framework.test import APIRequestFactory
from rest_framework.request import Request
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal
import random
from datetime import timedelta, date

# Import the report function (replace with your actual import)
from inventory.utils import create_order_report  # Adjust import path as needed

User = get_user_model()

class Command(BaseCommand):
    help = 'Create 210 orders and generate reports with random dates from the past 21 days (3 weeks)'

    def handle(self, *args, **options):
        customers = list(CustomerInfo.objects.all())
        products = list(Product.objects.all())
        user = User.objects.first()

        if not customers or not products or not user:
            self.stdout.write(self.style.ERROR('Missing required data: customers/products/user'))
            return

        factory = APIRequestFactory()
        dummy_request = factory.post('/api/inventory/orders/')
        request = Request(dummy_request)
        request.user = user

        success_count = 0
        fail_count = 0

        # Generate 210 orders
        for _ in range(210):
            customer = random.choice(customers)
            product = random.choice(products)

            # Skip bundles if not found
            if hasattr(product, 'is_bundle') and product.is_bundle and not hasattr(product, 'bundle'):
                fail_count += 1
                continue

            # Check stock
            if hasattr(product, 'stock') and product.stock < 1:
                fail_count += 1
                continue

            quantity = min(random.randint(1, 5), product.stock) if hasattr(product, 'stock') else random.randint(1, 5)
            unit_price = Decimal(str(product.selling_price)) if hasattr(product, 'selling_price') else Decimal('3000.00')

            data = {
                "customer": customer.id,
                "receipt": "No Receipt",
                "payment_status": "Paid",
                "paid_amount": float(unit_price * Decimal(quantity)),
                "items": [
                    {
                        "product": product.id,
                        "quantity": quantity,
                        "unit_price": float(unit_price)
                    }
                ]
            }

            serializer = OrderSerializer(data=data, context={'request': request})
            if serializer.is_valid():
                try:
                    order = serializer.save()
                    success_count += 1
                    # Randomize the report date
                    random_days_ago = random.randint(1, 21)
                    report_date = date.today() - timedelta(days=random_days_ago)
                    print(f"DEBUG: Random days ago: {random_days_ago}, Report date: {report_date}")  # Debug print
                    self.generate_order_report(order, user, unit_price, quantity, report_date)
                except Exception as e:
                    self.stdout.write(self.style.WARNING(f"Error saving order: {str(e)}"))
                    fail_count += 1
            else:
                self.stdout.write(self.style.WARNING(f"Invalid data: {serializer.errors}"))
                fail_count += 1

        self.stdout.write(self.style.SUCCESS(
            f"Completed: {success_count} successful orders, {fail_count} failed."
        ))

    def generate_order_report(self, order, user, unit_price, quantity, report_date):
        print(f"DEBUG: Inside generate_order_report, Report date: {report_date}")  # Debug print
        total_price = unit_price * Decimal(quantity)
        vat = total_price * Decimal('0.15')
        receipt_total_price = total_price + vat

        item = order.items.first()
        item_data = {
            'item_receipt': "Receipt",
            'unit': "pcs",
            'product': item.product,
            'quantity': quantity,
        }

        print(f"DEBUG: Creating report for order {order.id} with date: {report_date}")  # Debug print
        create_order_report(
            user=user.name,
            customer_name="Anonymous Customer" if order.customer is None else order.customer.name,
            customer_phone=" " if order.customer is None else order.customer.phone,
            customer_tin_number=" " if order.customer is None else order.customer.tin_number,
            order_date=report_date,  # Use the randomized report date
            order_id=order.id,
            item_receipt=item_data['item_receipt'],
            unit=item_data['unit'],
            product_name=item_data['product'].name,
            product_specification=item_data['product'].specification,
            product_price=float(unit_price),
            quantity=item_data['quantity'],
            sub_total=float(total_price),
            vat=float(vat),
            payment_status=order.payment_status,
            total_amount=float(receipt_total_price)
        )
