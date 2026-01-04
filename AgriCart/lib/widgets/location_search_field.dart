import 'package:flutter/material.dart';
import 'package:agricart/services/mapbox_service.dart';

typedef OnPlaceSelected = void Function(MapboxPlace place);

class LocationSearchField extends StatefulWidget {
  final String? initialValue;
  final OnPlaceSelected onPlaceSelected;

  const LocationSearchField({
    Key? key,
    this.initialValue,
    required this.onPlaceSelected,
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final _controller = TextEditingController();
  final _service = MapboxService();
  List<MapboxPlace> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) _controller.text = widget.initialValue!;
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    final res = await _service.searchPlaces(q);
    setState(() {
      _suggestions = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Search location',
            suffixIcon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          onChanged: (v) => _search(v),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return ListTile(
                  title: Text(s.text),
                  subtitle: Text(s.placeName),
                  onTap: () {
                    _controller.text = s.placeName;
                    setState(() => _suggestions = []);
                    widget.onPlaceSelected(s);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
