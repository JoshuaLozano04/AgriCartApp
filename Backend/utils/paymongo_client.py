"""
PayMongo client for payment processing.
"""
import requests
from django.conf import settings
from typing import Dict, Optional


class PayMongoClient:
    """Client for PayMongo API integration."""
    
    BASE_URL = "https://api.paymongo.com/v1"
    
    def __init__(self):
        self.secret_key = settings.PAYMONGO_SECRET_KEY
        self.public_key = settings.PAYMONGO_PUBLIC_KEY
    
    def _get_headers(self, use_secret: bool = True) -> Dict:
        """Get request headers with authentication."""
        key = self.secret_key if use_secret else self.public_key
        return {
            "Authorization": f"Basic {self._encode_key(key)}",
            "Content-Type": "application/json"
        }
    
    @staticmethod
    def _encode_key(key: str) -> str:
        """Encode API key for Basic Auth."""
        import base64
        encoded = base64.b64encode(f"{key}:".encode()).decode()
        return encoded
    
    def create_payment_intent(self, amount: float, currency: str = "PHP", description: str = "") -> Optional[Dict]:
        """
        Create a payment intent.
        
        Args:
            amount: Payment amount
            currency: Currency code (default: PHP)
            description: Payment description
            
        Returns:
            Payment intent data or None if failed
        """
        url = f"{self.BASE_URL}/payment_intents"
        data = {
            "data": {
                "attributes": {
                    "amount": int(amount * 100),  # Convert to centavos
                    "currency": currency,
                    "description": description
                }
            }
        }
        
        try:
            response = requests.post(url, json=data, headers=self._get_headers())
            response.raise_for_status()
            return response.json()
        except Exception:
            return None
    
    def create_payment_method(self, type: str, details: Dict) -> Optional[Dict]:
        """
        Create a payment method.
        
        Args:
            type: Payment method type (e.g., 'cod', 'gcash', 'grab_pay')
            details: Payment method details
            
        Returns:
            Payment method data or None if failed
        """
        url = f"{self.BASE_URL}/payment_methods"
        data = {
            "data": {
                "attributes": {
                    "type": type,
                    "details": details
                }
            }
        }
        
        try:
            response = requests.post(url, json=data, headers=self._get_headers(use_secret=False))
            response.raise_for_status()
            return response.json()
        except Exception:
            return None
    
    def attach_payment_method(self, payment_intent_id: str, payment_method_id: str) -> Optional[Dict]:
        """
        Attach payment method to payment intent.
        
        Args:
            payment_intent_id: Payment intent ID
            payment_method_id: Payment method ID
            
        Returns:
            Payment intent data or None if failed
        """
        url = f"{self.BASE_URL}/payment_intents/{payment_intent_id}/attach"
        data = {
            "data": {
                "attributes": {
                    "payment_method": payment_method_id
                }
            }
        }
        
        try:
            response = requests.post(url, json=data, headers=self._get_headers())
            response.raise_for_status()
            return response.json()
        except Exception:
            return None
    
    def retrieve_payment_intent(self, payment_intent_id: str) -> Optional[Dict]:
        """
        Retrieve payment intent details.
        
        Args:
            payment_intent_id: Payment intent ID
            
        Returns:
            Payment intent data or None if failed
        """
        url = f"{self.BASE_URL}/payment_intents/{payment_intent_id}"
        
        try:
            response = requests.get(url, headers=self._get_headers())
            response.raise_for_status()
            return response.json()
        except Exception:
            return None
    
    def create_source(self, amount: float, currency: str = "PHP", type: str = "gcash") -> Optional[Dict]:
        """
        Create a payment source for GCash, GrabPay, etc.
        
        Args:
            amount: Payment amount
            currency: Currency code (default: PHP)
            type: Source type (gcash, grab_pay, etc.)
            
        Returns:
            Source data or None if failed
        """
        url = f"{self.BASE_URL}/sources"
        data = {
            "data": {
                "attributes": {
                    "amount": int(amount * 100),
                    "currency": currency,
                    "type": type
                }
            }
        }
        
        try:
            response = requests.post(url, json=data, headers=self._get_headers(use_secret=False))
            response.raise_for_status()
            return response.json()
        except Exception:
            return None

