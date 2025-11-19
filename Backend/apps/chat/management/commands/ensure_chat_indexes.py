"""
Django management command to ensure MongoDB indexes for chat collections.
Run: python manage.py ensure_chat_indexes
"""
from django.core.management.base import BaseCommand
from utils.mongodb_service import MongoDBService
from apps.chat.schemas import ensure_indexes


class Command(BaseCommand):
    help = 'Ensure MongoDB indexes exist for chat collections (conversations, messages)'
    
    def handle(self, *args, **options):
        self.stdout.write('Creating MongoDB indexes for chat collections...')
        
        try:
            # Initialize MongoDB connection
            MongoDBService.initialize()
            
            # Ensure indexes
            ensure_indexes(MongoDBService)
            
            self.stdout.write(self.style.SUCCESS('✓ Successfully created/verified all chat indexes'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error creating indexes: {str(e)}'))
            raise
