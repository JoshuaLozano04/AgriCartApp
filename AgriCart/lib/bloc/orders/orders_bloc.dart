import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'orders_event.dart';
import 'orders_state.dart';
import '../../models/order.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiService apiService;

  OrdersBloc({required this.apiService}) : super(OrdersInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<LoadOrdersEvent>(_onLoadOrders);
    on<LoadOrderDetailsEvent>(_onLoadOrderDetails);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<CreatePaymentEvent>(_onCreatePayment);
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final response = await apiService.createOrder(event.order);
      if (response['success'] == true) {
        emit(OrderCreated(orderId: response['order_id']));
      } else {
        emit(OrdersError(message: response['message'] ?? 'Failed to create order'));
      }
    } catch (e) {
      emit(OrdersError(message: 'Error creating order: $e'));
    }
  }

  Future<void> _onLoadOrders(
    LoadOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final orders = await apiService.getOrders();
      emit(OrdersLoaded(orders: orders));
    } catch (e) {
      emit(OrdersError(message: 'Failed to load orders: $e'));
    }
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetailsEvent event,
    Emitter<OrdersState> emit,
  ) async {
    print('DEBUG OrdersBloc: Loading order details for orderId: ${event.orderId}');
    emit(OrdersLoading());
    try {
      print('DEBUG OrdersBloc: Calling apiService.getOrder(${event.orderId})');
      final order = await apiService.getOrder(event.orderId);
      print('DEBUG OrdersBloc: Received order: ${order != null ? "Order found" : "null"}');
      if (order != null) {
        print('DEBUG OrdersBloc: Emitting OrderDetailsLoaded');
        emit(OrderDetailsLoaded(order: order));
      } else {
        print('DEBUG OrdersBloc: Order not found, emitting error');
        emit(OrdersError(message: 'Order not found'));
      }
    } catch (e, stackTrace) {
      print('DEBUG OrdersBloc: Error loading order details: $e');
      print('DEBUG OrdersBloc: Stack trace: $stackTrace');
      emit(OrdersError(message: 'Failed to load order: $e'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatusEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final previousState = state;
    emit(OrdersLoading());
    try {
      final response = await apiService.updateOrderStatus(
        event.orderId,
        event.status,
        trackingNumber: event.trackingNumber,
      );
      if (response['success'] == true) {
        // Optimistic UI update: if we had a list loaded, update the item locally
        if (previousState is OrdersLoaded) {
          final currentOrders = previousState.orders;
          final updated = currentOrders.map((o) {
            if (o.orderId == event.orderId) {
              return Order(
                orderId: o.orderId,
                buyerId: o.buyerId,
                sellerId: o.sellerId,
                items: o.items,
                shippingAddress: o.shippingAddress,
                paymentMethod: o.paymentMethod,
                totalAmount: o.totalAmount,
                status: event.status,
                paymentStatus: o.paymentStatus,
                trackingNumber: event.trackingNumber ?? o.trackingNumber,
                createdAt: o.createdAt,
                updatedAt: o.updatedAt,
              );
            }
            return o;
          }).toList();
          emit(OrdersLoaded(orders: updated));
          // Also trigger background refresh to stay consistent with server
          add(const LoadOrdersEvent());
        } else if (previousState is OrderDetailsLoaded) {
          // If we were on details, reload the details
          add(LoadOrderDetailsEvent(orderId: previousState.order.orderId));
        } else {
          add(const LoadOrdersEvent());
        }
      } else {
        emit(OrdersError(message: response['message'] ?? 'Failed to update order status'));
      }
    } catch (e) {
      emit(OrdersError(message: 'Error updating order status: $e'));
    }
  }

  Future<void> _onCreatePayment(
    CreatePaymentEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final response = await apiService.createPayment(
        orderId: event.orderId,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
      );
      if (response['success'] == true) {
        final paymentUrl = response['payment_url'] as String?;
        emit(PaymentCreated(
          paymentUrl: paymentUrl,
          paymentMethod: event.paymentMethod,
        ));
      } else {
        emit(OrdersError(message: response['message'] ?? 'Failed to create payment'));
      }
    } catch (e) {
      emit(OrdersError(message: 'Error creating payment: $e'));
    }
  }
}

