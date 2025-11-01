"""
Serializers for user app.
"""
from rest_framework import serializers


class UserRegistrationSerializer(serializers.Serializer):
    """Serializer for user registration."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    full_name = serializers.CharField(max_length=255)
    phone_number = serializers.CharField(max_length=20)
    role = serializers.ChoiceField(choices=['buyer', 'seller', 'trader'])
    address = serializers.CharField(required=False, allow_blank=True)


class UserLoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class UserVerificationSerializer(serializers.Serializer):
    """Serializer for user verification."""
    user_id = serializers.CharField()
    verification_type = serializers.ChoiceField(choices=['id', 'phone'])
    verification_data = serializers.CharField()  # ID image or phone verification code


class UserProfileSerializer(serializers.Serializer):
    """Serializer for user profile."""
    user_id = serializers.CharField()
    email = serializers.EmailField(required=False)
    full_name = serializers.CharField(required=False)
    phone_number = serializers.CharField(required=False)
    address = serializers.CharField(required=False)
    role = serializers.CharField(required=False)
    is_verified = serializers.BooleanField(required=False)
    profile_image_id = serializers.CharField(required=False, allow_null=True)

