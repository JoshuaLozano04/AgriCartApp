import uuid
import random
from django.core.management.base import BaseCommand

from utils.mongodb_service import MongoDBService


class Command(BaseCommand):
    help = 'Seed 5 products for each category using an existing seller.'

    def handle(self, *args, **options):
        categories = [
            'fresh_produce',
            'livestock_poultry',
            'seeds_fertilizers',
            'farm_tools',
            'processed_goods',
        ]

        # Curated real products per category
        product_catalog = {
            'fresh_produce': [
                {'name': 'Tomatoes (Fresh)', 'price': 80.0, 'unit': 'kg', 'description': 'Fresh, locally sourced tomatoes.'},
                {'name': 'Eggplant (Talong)', 'price': 70.0, 'unit': 'kg', 'description': 'Farm-fresh eggplants.'},
                {'name': 'Calamansi', 'price': 120.0, 'unit': 'kg', 'description': 'Fresh calamansi for juice and cooking.'},
                {'name': 'Mango (Carabao)', 'price': 150.0, 'unit': 'kg', 'description': 'Sweet carabao mangoes from Guimaras.'},
                {'name': 'Cabbage (Repolyo)', 'price': 60.0, 'unit': 'kg', 'description': 'Crisp green cabbage.'},
            ],
            'livestock_poultry': [
                {'name': 'Chicken Broiler (Whole)', 'price': 190.0, 'unit': 'kg', 'description': 'Fresh dressed chicken, whole.'},
                {'name': 'Pork Liempo', 'price': 320.0, 'unit': 'kg', 'description': 'Pork belly cut, great for grilling.'},
                {'name': 'Beef Brisket', 'price': 380.0, 'unit': 'kg', 'description': 'Beef brisket cut, ideal for stews.'},
                {'name': 'Chicken Eggs (Large, per tray)', 'price': 210.0, 'unit': 'tray', 'description': '30 pcs large eggs, per tray.'},
                {'name': 'Tilapia (Fresh)', 'price': 160.0, 'unit': 'kg', 'description': 'Fresh farmed tilapia.'},
            ],
            'seeds_fertilizers': [
                {'name': 'Hybrid Rice Seeds (20kg bag)', 'price': 2500.0, 'unit': 'bag', 'description': 'High-yield hybrid rice seeds.'},
                {'name': 'Urea Fertilizer 46-0-0 (50kg)', 'price': 1800.0, 'unit': 'bag', 'description': 'Nitrogen fertilizer for vegetative growth.'},
                {'name': 'Complete Fertilizer 14-14-14 (50kg)', 'price': 1700.0, 'unit': 'bag', 'description': 'Balanced NPK fertilizer.'},
                {'name': 'Corn Seeds (10kg)', 'price': 1600.0, 'unit': 'bag', 'description': 'Quality hybrid corn seeds.'},
                {'name': 'Vermicompost (25kg)', 'price': 350.0, 'unit': 'bag', 'description': 'Organic soil conditioner.'},
            ],
            'farm_tools': [
                {'name': 'Bolo (Itak)', 'price': 250.0, 'unit': 'piece', 'description': 'Traditional Filipino machete for field work.'},
                {'name': 'Hand Tiller', 'price': 2200.0, 'unit': 'piece', 'description': 'Manual soil tiller for small plots.'},
                {'name': 'Knapsack Sprayer (16L)', 'price': 1500.0, 'unit': 'piece', 'description': 'Manual sprayer for pesticides and foliar feeding.'},
                {'name': 'Shovel (Steel)', 'price': 600.0, 'unit': 'piece', 'description': 'Heavy-duty steel shovel.'},
                {'name': 'Garden Hoe', 'price': 350.0, 'unit': 'piece', 'description': 'Durable hoe for weeding and soil cultivation.'},
            ],
            'processed_goods': [
                {'name': 'Dried Mangoes 200g', 'price': 120.0, 'unit': 'pack', 'description': 'Premium dried mango slices.'},
                {'name': 'Banana Chips 200g', 'price': 90.0, 'unit': 'pack', 'description': 'Crispy sweet banana chips.'},
                {'name': 'Coconut Sugar 1kg', 'price': 180.0, 'unit': 'pack', 'description': 'Natural coconut sap sugar.'},
                {'name': 'Peanut Butter 340g', 'price': 150.0, 'unit': 'pack', 'description': 'All-natural creamy peanut butter.'},
                {'name': 'Tablea Cacao 250g', 'price': 180.0, 'unit': 'pack', 'description': 'Pure tablea cacao tablets.'},
            ],
        }

        # Find an existing seller
        seller = None
        sellers = MongoDBService.query_collection(
            'users',
            filters=[('role', '==', 'seller')],
            limit=1,
        )
        if sellers:
            seller = sellers[0]

        if not seller:
            self.stdout.write(self.style.ERROR('No existing seller found (users.role == "seller"). Aborting.'))
            return

        seller_id = seller.get('user_id') or seller.get('_id')
        if not seller_id:
            self.stdout.write(self.style.ERROR('Existing seller found but has no user_id or _id. Aborting.'))
            return

        total_created = 0

        def unit_for(category: str) -> str:
            if category == 'fresh_produce':
                return 'kg'
            if category == 'livestock_poultry':
                return 'kg'
            if category == 'seeds_fertilizers':
                return 'bag'
            if category == 'farm_tools':
                return 'piece'
            if category == 'processed_goods':
                return 'pack'
            return 'piece'

        for category in categories:
            items = product_catalog.get(category, [])
            for product in items[:5]:
                product_id = str(uuid.uuid4())

                product_doc = {
                    'product_id': product_id,
                    'seller_id': seller_id,
                    'name': product['name'],
                    'description': product.get('description', f'{product["name"]}'),
                    'category': category,
                    'price': float(product['price']),
                    'quantity': 500,
                    'unit': product.get('unit', unit_for(category)),
                    'location': 'Manila, Philippines',
                    'latitude': 14.5995,
                    'longitude': 120.9842,
                    'image_paths': [],
                    'is_active': True,
                    'created_at': 'SERVER_TIMESTAMP',
                    'updated_at': 'SERVER_TIMESTAMP',
                }

                MongoDBService.create_document('products', product_doc, product_id)
                total_created += 1

            self.stdout.write(self.style.SUCCESS(f'Created 5 products for category: {category}'))

        self.stdout.write(self.style.SUCCESS(f'Seeding complete. Total products created: {total_created}'))


