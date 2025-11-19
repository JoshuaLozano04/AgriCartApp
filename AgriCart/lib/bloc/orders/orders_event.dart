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
  // userId and role no longer needed - comes from token
  const LoadOrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrderDetailsEvent extends OrdersEvent {
  final String orderId;

  const LoadOrderDetailsEvent({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class UpdateOrderStatusEvent extends OrdersEvent {
  final String orderId;
  final String status;
  final String? trackingNumber;

  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.status,
    this.trackingNumber,
  });

  @override
  List<Object?> get props => [orderId, status, trackingNumber];
}

class CreatePaymentEvent extends OrdersEvent {
  final String orderId;
  final String paymentMethod;
  final double amount;

  const CreatePaymentEvent({
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
  });

  @override
  List<Object?> get props => [orderId, paymentMethod, amount];
}

