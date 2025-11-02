import 'package:equatable/equatable.dart';
import '../../models/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;

  const OrdersLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class OrderDetailsLoaded extends OrdersState {
  final Order order;

  const OrderDetailsLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderCreated extends OrdersState {
  final String orderId;

  const OrderCreated({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PaymentCreated extends OrdersState {
  final String? paymentUrl;
  final String paymentMethod;

  const PaymentCreated({
    this.paymentUrl,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [paymentUrl, paymentMethod];
}

