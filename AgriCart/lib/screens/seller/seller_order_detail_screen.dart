import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../bloc/orders/orders_event.dart';
import '../../bloc/orders/orders_state.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<latlng.LatLng>> _getRouteForSeller(double startLat, double startLng, double endLat, double endLng, String token) async {
  try {
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat?geometries=geojson&access_token=$token';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
      return coordinates.map((coord) => latlng.LatLng(coord[1], coord[0])).toList();
    }
  } catch (e) {
    print('Error fetching route: $e');
  }
  return [latlng.LatLng(startLat, startLng), latlng.LatLng(endLat, endLng)];
}

class SellerOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const SellerOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersBloc(apiService: ApiService())
        ..add(LoadOrderDetailsEvent(orderId: orderId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
        ),
        backgroundColor: AppTheme.backgroundGray,
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              );
            }
            if (state is OrdersError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.textGray),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center, style: AppTheme.bodyMedium),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .read<OrdersBloc>()
                            .add(LoadOrderDetailsEvent(orderId: orderId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            }
            if (state is OrderDetailsLoaded) {
              final order = state.order;
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<OrdersBloc>().add(LoadOrderDetailsEvent(orderId: orderId));
                  await Future.delayed(const Duration(milliseconds: 400));
                },
                color: AppTheme.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(order: order),
                      const SizedBox(height: 12),
                      _StatusTimeline(status: order.status),
                      const SizedBox(height: 12),
                      _AddressAndPayment(order: order),
                      const SizedBox(height: 12),
                      _ItemsList(order: order),
                      const SizedBox(height: 12),
                      _Summary(order: order),
                      const SizedBox(height: 20),
                      _Actions(order: order),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Order order;
  const _Header({required this.order});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return AppTheme.warningOrange;
      case 'confirmed':
        return AppTheme.infoBlue;
      case 'processing':
        return AppTheme.primaryGreen;
      case 'shipped':
        return AppTheme.primaryGreenDark;
      case 'delivered':
        return AppTheme.successGreen;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order #${order.orderId.substring(0, 8).toUpperCase()}',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(order.status.toUpperCase(),
                    style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Payment: ${(order.paymentStatus ?? 'pending').toUpperCase()}',
                    style: const TextStyle(color: AppTheme.infoBlue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  List<String> get _steps => const ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(status.toLowerCase());
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _steps.map((s) {
          final idx = _steps.indexOf(s);
          final reached = idx <= currentIndex;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: reached ? AppTheme.primaryGreen : AppTheme.textGray.withOpacity(0.3),
                ),
                const SizedBox(height: 6),
                Text(
                  s[0].toUpperCase() + s.substring(1),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AddressAndPayment extends StatelessWidget {
  final Order order;
  const _AddressAndPayment({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipping Address', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(order.shippingAddress, style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            FutureBuilder(
              future: order.items.isNotEmpty ? ApiService().getProduct(order.items.first.productId) : Future.value(null),
              builder: (context, snapshot) {
                final product = snapshot.data as dynamic;
                final sellerLat = product?.latitude as double?;
                final sellerLng = product?.longitude as double?;
                final destLat = order.shippingLatitude;
                final destLng = order.shippingLongitude;

                if (sellerLat == null || sellerLng == null || destLat == null || destLng == null) {
                  return const SizedBox();
                }

                final center = latlng.LatLng((sellerLat + destLat) / 2, (sellerLng + destLng) / 2);
                final mapboxToken = dotenv.env['MAPBOX_API_KEY'] ?? '';
                
                // Calculate zoom to fit both markers
                final latDiff = (sellerLat - destLat).abs();
                final lngDiff = (sellerLng - destLng).abs();
                final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
                double zoomLevel = 10;
                if (maxDiff > 0.5) zoomLevel = 8;
                else if (maxDiff > 0.2) zoomLevel = 9;
                else if (maxDiff > 0.1) zoomLevel = 9.5;

                return FutureBuilder<List<latlng.LatLng>>(
                  future: _getRouteForSeller(sellerLat, sellerLng, destLat, destLng, mapboxToken),
                  builder: (context, routeSnapshot) {
                    final routePoints = routeSnapshot.data ?? [
                      latlng.LatLng(sellerLat, sellerLng),
                      latlng.LatLng(destLat, destLng)
                    ];

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.textGray.withOpacity(0.2), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FlutterMap(
                          options: MapOptions(
                            center: center,
                            zoom: zoomLevel,
                            interactiveFlags: InteractiveFlag.none,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken',
                              additionalOptions: {'accessToken': mapboxToken},
                            ),
                            PolylineLayer(polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 4.0,
                                color: Colors.blue.shade600,
                              ),
                            ]),
                            MarkerLayer(markers: [
                              Marker(
                                width: 50,
                                height: 50,
                                point: latlng.LatLng(sellerLat, sellerLng),
                                builder: (ctx) => Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.local_shipping, color: Colors.blue, size: 28),
                                ),
                              ),
                              Marker(
                                width: 50,
                                height: 50,
                                point: latlng.LatLng(destLat, destLng),
                                builder: (ctx) => Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 28),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payment, size: 18, color: AppTheme.textGray),
              const SizedBox(width: 6),
              Text('Payment Method: ${order.paymentMethod.toUpperCase()}', style: AppTheme.bodyMedium),
            ],
          ),
          if ((order.trackingNumber ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: AppTheme.textGray),
                const SizedBox(width: 6),
                Text('Tracking: ${order.trackingNumber}', style: AppTheme.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final Order order;
  const _ItemsList({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('x${it.quantity}  ₱${it.price.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                    ),
                    Text('₱${(it.price * it.quantity).toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final Order order;
  const _Summary({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
          Text('₱${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final Order order;
  const _Actions({required this.order});

  String? _next(String current) {
    switch (current.toLowerCase()) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'processing';
      case 'processing':
        return 'shipped';
      case 'shipped':
        return 'delivered';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _next(order.status);
    if (next == null) return const SizedBox();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          String? tracking;
          if (next == 'shipped') {
            tracking = await showDialog<String?>(
              context: context,
              builder: (ctx) {
                final controller = TextEditingController();
                return AlertDialog(
                  title: const Text('Enter Tracking Number'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Tracking number'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
                  ],
                );
              },
            );
            if (tracking == null || tracking.isEmpty) return;
          }

          context.read<OrdersBloc>().add(UpdateOrderStatusEvent(
                orderId: order.orderId,
                status: next,
                trackingNumber: tracking,
              ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to ${next.toUpperCase()}')),
          );
          // Reload details
          context.read<OrdersBloc>().add(LoadOrderDetailsEvent(orderId: order.orderId));
        },
        icon: const Icon(Icons.update),
        label: Text('Mark as ${next[0].toUpperCase()}${next.substring(1)}'),
      ),
    );
  }
}


