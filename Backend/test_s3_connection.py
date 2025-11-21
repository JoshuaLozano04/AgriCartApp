import boto3
import os
from io import BytesIO

# Set environment variables
os.environ['AWS_ACCESS_KEY_ID'] = 'AKIAQABFJHQJLFHRGHV3'
os.environ['AWS_SECRET_ACCESS_KEY'] = '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'
os.environ['AWS_S3_BUCKET_NAME'] = 'agricart-images'
os.environ['AWS_S3_REGION'] = 'ap-southeast-2'

# Test S3 connection
try:
    s3_client = boto3.client(
        's3',
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
        region_name=os.getenv('AWS_S3_REGION')
    )
    
    print('Testing S3 connection...')
    bucket_name = os.getenv('AWS_S3_BUCKET_NAME')
    
    # List objects to verify connection
    response = s3_client.list_objects_v2(Bucket=bucket_name, MaxKeys=1)
    print('✓ S3 connection successful!')
    print(f'Bucket: {bucket_name}')
    print(f'Region: {os.getenv("AWS_S3_REGION")}')
    
    # Test upload
    print('\nTesting file upload...')
    test_content = b'Test image content'
    file_obj = BytesIO(test_content)
    test_key = 'products/test-upload.txt'
    
    s3_client.upload_fileobj(
        file_obj,
        bucket_name,
        test_key,
        ExtraArgs={'ContentType': 'text/plain'}
    )
    
    test_url = f"https://{bucket_name}.s3.{os.getenv('AWS_S3_REGION')}.amazonaws.com/{test_key}"
    print(f'✓ Upload successful!')
    print(f'Test file URL: {test_url}')
    
    # Clean up test file
    s3_client.delete_object(Bucket=bucket_name, Key=test_key)
    print('✓ Test file cleaned up')
    
except Exception as e:
    print(f'✗ Error: {str(e)}')
    import traceback
    traceback.print_exc()
