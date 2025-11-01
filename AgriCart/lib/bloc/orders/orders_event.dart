import 'package:equatable/equatable.dart';
import '../../models/order.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class CreateOrderEvent extends OrdersEvent {
  final Order order;

  const CreateOrderEvent({required this.order});

  @override
  List<Object?> get props => [order];
}

class LoadOrdersEvent extends OrdersEvent {
  final String userId;
  final String role; // 'buyer' or 'seller'

  const LoadOrdersEvent({required this.userId, required this.role});

  @override
  List<Object?> get props => [userId, role];
}

class LoadOrderDetailsEvent extends OrdersEvent {
  final String orderId;

  const LoadOrderDetailsEvent({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

