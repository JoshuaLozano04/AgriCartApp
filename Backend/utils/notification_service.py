from typing import Optional, Dict, Any, List
import uuid
from datetime import datetime, timezone
from .mongodb_service import MongoDBService
from .fcm_service import FCMService


class NotificationService:
	"""Service for persisting and delivering notifications.
	Stores notifications in MongoDB and sends push via FCM when unread.
	"""

	COLLECTION = 'notifications'

	def __init__(self):
		self.fcm = FCMService()

	def create_notification(self,
							user_id: str,
							notification_type: str,
							title: str,
							body: str,
							data: Optional[Dict[str, Any]] = None) -> str:
		"""Create a notification document (unread by default)."""
		notification_id = str(uuid.uuid4())
		doc = {
			'notification_id': notification_id,
			'user_id': user_id,
			'type': notification_type,
			'title': title,
			'body': body,
			'data': data or {},
			'is_read': False,
			'created_at': 'SERVER_TIMESTAMP',
			'updated_at': 'SERVER_TIMESTAMP'
		}
		try:
			print(f"Creating notification in collection '{self.COLLECTION}' for user {user_id} ...")
			MongoDBService.create_document(self.COLLECTION, doc, notification_id)
		except Exception as e:
			print(f"NotificationService.create_notification error: {e}")
			raise
		return notification_id

	def list_notifications(self, user_id: str, unread_only: bool = False, limit: int = 50) -> List[Dict[str, Any]]:
		filters = [('user_id', '==', user_id)]
		if unread_only:
			filters.append(('is_read', '==', False))
		return MongoDBService.query_collection(self.COLLECTION, filters=filters, order_by='-created_at', limit=limit)

	def mark_read(self, notification_id: str) -> bool:
		return MongoDBService.update_document(self.COLLECTION, notification_id, {
			'is_read': True,
			'read_at': 'SERVER_TIMESTAMP',
			'updated_at': 'SERVER_TIMESTAMP',
		})

	def mark_all_read(self, user_id: str) -> int:
		return MongoDBService.update_many(self.COLLECTION, {
			'user_id': user_id,
			'is_read': False,
		}, {
			'is_read': True,
			'read_at': 'SERVER_TIMESTAMP',
			'updated_at': 'SERVER_TIMESTAMP',
		})

	def send_unread_for_user(self, user_id: str) -> int:
		"""Send all unread notifications for a user via FCM, prune invalid tokens, return sent count."""
		unread = self.list_notifications(user_id, unread_only=True, limit=100)
		if not unread:
			return 0
		# fetch tokens
		user = MongoDBService.get_document('users', user_id)
		if not user:
			return 0
		tokens = user.get('fcm_tokens', []) or []
		if not tokens:
			return 0
		# send each notification as separate push (ensures per-item payload)
		sent_count = 0
		for notif in unread:
			result = self.fcm.send_multicast_notification(
				tokens,
				notif.get('title', ''),
				notif.get('body', ''),
				{'type': notif.get('type', ''), **(notif.get('data') or {}), 'notification_id': notif.get('notification_id', '')}
			)
			# prune invalid tokens
			invalid = result.get('invalid_tokens', []) if isinstance(result, dict) else []
			if invalid:
				updated = [t for t in tokens if t not in invalid]
				MongoDBService.update_document('users', user_id, {
					'fcm_tokens': updated,
					'updated_at': 'SERVER_TIMESTAMP',
				})
			if isinstance(result, dict) and result.get('success_count', 0) > 0:
				sent_count += 1
		return sent_count
