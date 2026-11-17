import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  static const _stores = [
    _StoreLocation(
      name: 'CellphoneS',
      address: '347 Nguyễn Tri Phương, Phường 5, Quận 10, TP.HCM',
      hours: '08:00 - 22:00',
      location: LatLng(10.7625194, 106.6681313),
      googleMapsUrl: 'https://maps.app.goo.gl/RgawMWHqipqbNWTg7',
    ),
    _StoreLocation(
      name: 'CellphoneS',
      address: '672-674 Âu Cơ, P.14, Q. Tân Bình, TP.HCM',
      hours: '08:00 - 22:00',
      location: LatLng(10.7873, 106.6415),
    ),
    _StoreLocation(
      name: 'CellphoneS',
      address: '458-460 Hậu Giang, P.12, Q.6, TP.HCM',
      hours: '08:00 - 22:00',
      location: LatLng(10.7496, 106.6379),
    ),
    _StoreLocation(
      name: 'CellphoneS',
      address: '785 Trần Hưng Đạo, P.1, Q.5, TP.HCM',
      hours: '08:00 - 22:00',
      location: LatLng(10.7552739, 106.6816235),
    ),
  ];
  static const _mapCenter = LatLng(10.7665, 106.6595);

  final MapController _mapController = MapController();
  String _searchQuery = '';
  _StoreLocation? _selectedStore = _stores.first;

  List<_StoreLocation> get _visibleStores {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _stores;
    return _stores
        .where(
          (store) =>
              '${store.name} ${store.address}'.toLowerCase().contains(query),
        )
        .toList();
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;
      if (!_visibleStores.contains(_selectedStore)) {
        _selectedStore = _visibleStores.isEmpty ? null : _visibleStores.first;
      }
    });
  }

  void _selectStore(_StoreLocation store) {
    setState(() => _selectedStore = store);
    _mapController.move(store.location, 13.5);
  }

  Future<void> _openExternalLink(Uri uri, String failureMessage) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleStores = _visibleStores;
    final selectedStore = _selectedStore;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 12.8,
                    minZoom: 5,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.appdienthoai',
                    ),
                    if (visibleStores.isNotEmpty)
                      MarkerLayer(
                        markers: visibleStores.map((store) {
                          return Marker(
                            point: store.location,
                            width: 158,
                            height: 58,
                            alignment: Alignment.bottomLeft,
                            child: GestureDetector(
                              onTap: () => _selectStore(store),
                              child: _StoreMapMarker(
                                store: store,
                                selected: store == selectedStore,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      showFlutterMapAttribution: false,
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => _openExternalLink(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                            'Không thể mở thông tin bản đồ.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(28),
                          child: TextField(
                            onChanged: (value) {
                              _updateSearch(value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Bạn muốn tìm shop gần khu vực nào?',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xff8892a0),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Expanded(
                              child: _MapFilterPill(
                                label: 'Chọn Tỉnh/ Thành phố',
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _MapFilterPill(label: 'Chọn Quận/ Huyện'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 14,
                  child: FloatingActionButton.small(
                    heroTag: 'store_map_location',
                    backgroundColor: Colors.white,
                    foregroundColor: appRed,
                    onPressed: () {
                      final target = _selectedStore?.location ?? _mapCenter;
                      _mapController.move(target, 13.5);
                    },
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ),
              ],
            ),
          ),
          if (selectedStore != null)
            _StoreDetailsPanel(
              storeName: selectedStore.name,
              address: selectedStore.address,
              hours: selectedStore.hours,
              onDirectionsTap: () => _openExternalLink(
                selectedStore.directionsUri,
                'Không thể mở Google Maps.',
              ),
            )
          else
            const _NoStoresFoundPanel(),
        ],
      ),
    );
  }
}

class _StoreLocation {
  final String name;
  final String address;
  final String hours;
  final LatLng location;
  final String? googleMapsUrl;

  const _StoreLocation({
    required this.name,
    required this.address,
    required this.hours,
    required this.location,
    this.googleMapsUrl,
  });

  Uri get directionsUri {
    final url = googleMapsUrl;
    if (url != null) return Uri.parse(url);
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
  }
}

class _StoreMapMarker extends StatelessWidget {
  final _StoreLocation store;
  final bool selected;

  const _StoreMapMarker({required this.store, required this.selected});

  @override
  Widget build(BuildContext context) {
    final pinSize = selected ? 42.0 : 38.0;
    return SizedBox(
      width: 158,
      height: 58,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(Icons.location_on, color: appRed, size: pinSize),
          ),
          Positioned(
            left: selected ? 12 : 11,
            bottom: selected ? 13 : 12,
            child: Icon(
              Icons.storefront,
              color: Colors.white,
              size: selected ? 15 : 14,
            ),
          ),
          Positioned(
            left: 32,
            right: 0,
            bottom: 17,
            child: Text(
              store.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: appRed,
                fontSize: 9,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFilterPill extends StatelessWidget {
  final String label;

  const _MapFilterPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff1769c2),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }
}

class _StoreDetailsPanel extends StatelessWidget {
  final String storeName;
  final String address;
  final String hours;
  final VoidCallback onDirectionsTap;

  const _StoreDetailsPanel({
    required this.storeName,
    required this.address,
    required this.hours,
    required this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffd9dce1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            children: [
              _StoreTag(label: 'CellphoneS', selected: true),
              _StoreTag(label: 'Điện Thoại Vui'),
              _StoreTag(label: 'CareS'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$storeName $address',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(address, style: const TextStyle(color: Color(0xff7b8795))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mở cửa: $hours (tất cả các ngày trong tuần)',
                  style: const TextStyle(
                    color: Color(0xff7b8795),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDirectionsTap,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Chỉ đường'),
                style: TextButton.styleFrom(
                  foregroundColor: appRed,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreTag extends StatelessWidget {
  final String label;
  final bool selected;

  const _StoreTag({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? appRed : const Color(0xff64748b);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xfffff4f4) : Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _NoStoresFoundPanel extends StatelessWidget {
  const _NoStoresFoundPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Không tìm thấy cửa hàng phù hợp.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
