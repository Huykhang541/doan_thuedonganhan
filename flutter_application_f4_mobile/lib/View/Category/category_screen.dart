

import 'package:flutter/material.dart';
// Thay đường dẫn import cho đúng với project của bạn
import '../../Controller/brandsController.dart';
import '../../Model/brandsModel.dart';
import 'product_by_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<BrandsModel>> _futureBrands;

  @override
  void initState() {
    super.initState();
    _futureBrands = BrandsController.getAllBrands();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth >= 1200 ? 5 : screenWidth >= 800 ? 4 : 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Danh mục sản phẩm",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<BrandsModel>>(
        future: _futureBrands,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Đã xảy ra lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có danh mục nào"));
          }

          final List<BrandsModel> brands = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: brands.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0, 
              ),
              itemBuilder: (context, index) {
                final cat = brands[index];
                return _HoverCategoryCard(
                  cat: cat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductByCategoryScreen(
                          category_id: cat.id,
                          nameBrands: cat.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HoverCategoryCard extends StatefulWidget {
  final BrandsModel cat;
  final VoidCallback onTap;

  const _HoverCategoryCard({
    required this.cat,
    required this.onTap,
  });

  @override
  State<_HoverCategoryCard> createState() => _HoverCategoryCardState();
}

class _HoverCategoryCardState extends State<_HoverCategoryCard> {
  bool _isHovering = false;
  
  final Map<String, String> _imageHeaders = const {
    "ngrok-skip-browser-warning": "true",
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovering ? Colors.black : Colors.transparent,
              width: _isHovering ? 1.5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovering ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.06),
                blurRadius: _isHovering ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, 
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5F5F5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  // Xử lý an toàn nếu imageUrl rỗng
                  child: widget.cat.image_url.isNotEmpty 
                    ? Image.network(
                        widget.cat.image_url,
                        headers: _imageHeaders,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.category, color: Colors.grey),
                      )
                    : const Icon(Icons.category, color: Colors.grey, size: 30),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  widget.cat.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isHovering ? Colors.black : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}