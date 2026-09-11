// lib/screens/image_search_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/component_model.dart';
import '../models/inventory_model.dart';
import '../services/component_service.dart';
import '../services/inventory_service.dart';
import '../services/location_service.dart';
import '../services/image_search_service.dart';
import 'admin/component_detail_screen.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);

  final _imageSearchService = ImageSearchService();
  final _componentService = ComponentService();
  final _inventoryService = InventoryService();
  final _locationService = LocationService();

  XFile? _pickedImage;
  bool _isSearching = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _matches = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    setState(() {
      _pickedImage = image;
      _matches = [];
      _errorMessage = null;
    });
  }

  Future<void> _findMatches() async {
    if (_pickedImage == null) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _matches = [];
    });

    try {
      final results = await _imageSearchService.searchByImage(_pickedImage!);
      setState(() => _matches = results);
    } catch (e) {
      setState(() => _errorMessage = 'Search failed: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _reset() {
    setState(() {
      _pickedImage = null;
      _matches = [];
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Find Component by Image'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_pickedImage == null) ...[
            const Text(
              'Take a photo of a component to find matching items in the lab inventory.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],

          // Image preview area
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: _pickedImage == null
                ? const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.white38,
                      size: 56,
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                      if (_isSearching)
                        Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Analyzing image...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Finding matches in inventory...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (_pickedImage == null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Camera',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            )
          else if (_matches.isEmpty && !_isSearching)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _findMatches,
                    child: const Text(
                      'Find Matching Components',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retake'),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Upload'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],

          if (!_isSearching &&
              _matches.isEmpty &&
              _pickedImage != null &&
              _errorMessage == null) ...[
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'No confident matches found. Try a clearer photo.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],

          // Results
          if (_matches.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Possible Matches',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Search Again',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._matches.map(
              (match) => _MatchCard(
                componentId: match['componentId'],
                similarity: match['similarity'],
                componentService: _componentService,
                inventoryService: _inventoryService,
                locationService: _locationService,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String componentId;
  final double similarity;
  final ComponentService componentService;
  final InventoryService inventoryService;
  final LocationService locationService;

  const _MatchCard({
    required this.componentId,
    required this.similarity,
    required this.componentService,
    required this.inventoryService,
    required this.locationService,
  });

  static const Color primaryColor = Color(0xFF6C63FF);

  Color _matchColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ComponentModel?>(
      future: componentService.getComponent(componentId),
      builder: (context, compSnap) {
        if (!compSnap.hasData || compSnap.data == null) {
          return const SizedBox.shrink();
        }
        final component = compSnap.data!;
        final matchPercent = (similarity * 100)
            .clamp(0, 100)
            .toStringAsFixed(0);
        final matchColor = _matchColor(similarity);

        return FutureBuilder<List<InventoryModel>>(
          future: inventoryService.getInventoryForComponent(componentId).first,
          builder: (context, invSnap) {
            final records = invSnap.data ?? [];
            final totalQty = records.fold<int>(0, (sum, r) => sum + r.quantity);
            final isOut = totalQty == 0;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ComponentDetailScreen(component: component),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.memory, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  component.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: matchColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$matchPercent% Match',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: matchColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            component.componentCode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (records.isNotEmpty)
                                Text(
                                  'Bin: ${records.first.locationId.split('_').last}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                isOut ? 'Out of Stock' : '$totalQty Available',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOut ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
