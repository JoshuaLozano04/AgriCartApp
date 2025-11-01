import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ApiService apiService;

  ProductsBloc({required this.apiService}) : super(ProductsInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<LoadProductDetailsEvent>(_onLoadProductDetails);
    on<RefreshProductsEvent>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await apiService.getProducts(
        category: event.category,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        location: event.location,
        search: event.search,
        sellerId: event.sellerId,
      );
      emit(ProductsLoaded(products: products));
    } catch (e) {
      emit(ProductsError(message: 'Failed to load products: $e'));
    }
  }

  Future<void> _onLoadProductDetails(
    LoadProductDetailsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final product = await apiService.getProduct(event.productId);
      if (product != null) {
        emit(ProductDetailsLoaded(product: product));
      } else {
        emit(ProductsError(message: 'Product not found'));
      }
    } catch (e) {
      emit(ProductsError(message: 'Failed to load product: $e'));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await apiService.getProducts(
        category: event.category,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        location: event.location,
        search: event.search,
      );
      emit(ProductsLoaded(products: products));
    } catch (e) {
      emit(ProductsError(message: 'Failed to refresh products: $e'));
    }
  }
}

