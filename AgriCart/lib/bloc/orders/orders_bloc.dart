import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiService apiService;

  OrdersBloc({required this.apiService}) : super(OrdersInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<LoadOrdersEvent>(_onLoadOrders);
    on<LoadOrderDetailsEvent>(_onLoadOrderDetails);
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
      final orders = await apiService.getOrders(event.userId, event.role);
      emit(OrdersLoaded(orders: orders));
    } catch (e) {
      emit(OrdersError(message: 'Failed to load orders: $e'));
    }
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetailsEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final order = await apiService.getOrder(event.orderId);
      if (order != null) {
        emit(OrderDetailsLoaded(order: order));
      } else {
        emit(OrdersError(message: 'Order not found'));
      }
    } catch (e) {
      emit(OrdersError(message: 'Failed to load order: $e'));
    }
  }
}

