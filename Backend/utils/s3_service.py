import boto3
from botocore.exceptions import NoCredentialsError
import os

AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_S3_BUCKET_NAME = os.getenv('AWS_S3_BUCKET_NAME')
AWS_S3_REGION = os.getenv('AWS_S3_REGION', 'us-east-1')

s3_client = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_S3_REGION
)

def upload_file_to_s3(file_obj, filename, folder='products', content_type='image/jpeg'):
    """
    Uploads a file object to S3 and returns the public URL.
    
    Args:
        file_obj: File-like object to upload
        filename: Name for the file in S3
        folder: Folder path in S3 bucket
        content_type: MIME type of the file
    """
    key = f"{folder}/{filename}"
    try:
        s3_client.upload_fileobj(
            file_obj,
            AWS_S3_BUCKET_NAME,
            key,
            ExtraArgs={"ContentType": content_type}
        )
        url = f"https://{AWS_S3_BUCKET_NAME}.s3.{AWS_S3_REGION}.amazonaws.com/{key}"
        return url
    except NoCredentialsError:
        raise Exception("AWS credentials not found.")
    except Exception as e:
        raise Exception(f"S3 upload failed: {str(e)}")
