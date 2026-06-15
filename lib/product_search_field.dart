import 'package:flutter/material.dart';
import 'skincare_products.dart';

class ProductSearchField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> selectedProducts;
  final Function(List<String>) onChanged;

  const ProductSearchField({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selectedProducts,
    required this.onChanged,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SkincareProduct> _results = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() { _results = []; _showDropdown = false; });
      return;
    }
    final lower = query.toLowerCase();
    final results = ProductDatabase.products.where((p) {
      return p.name.toLowerCase().contains(lower) ||
          p.brand.toLowerCase().contains(lower) ||
          p.category.toLowerCase().contains(lower) ||
          p.keywords.any((k) => k.toLowerCase().contains(lower));
    }).take(6).toList();
    setState(() {
      _results = results;
      _showDropdown = results.isNotEmpty || query.length > 2;
    });
  }

  void _selectProduct(String name) {
    if (!widget.selectedProducts.contains(name)) {
      widget.onChanged([...widget.selectedProducts, name]);
    }
    _searchController.clear();
    setState(() { _results = []; _showDropdown = false; });
    _focusNode.unfocus();
  }

  void _addFreeText() {
    final text = _searchController.text.trim();
    if (text.isNotEmpty && !widget.selectedProducts.contains(text)) {
      widget.onChanged([...widget.selectedProducts, text]);
    }
    _searchController.clear();
    setState(() { _results = []; _showDropdown = false; });
    _focusNode.unfocus();
  }

  void _removeProduct(String name) {
    widget.onChanged(widget.selectedProducts.where((p) => p != name).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha: 0.25)),
        gradient: LinearGradient(colors: [
          widget.color.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.02),
        ]),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(widget.icon, size: 15, color: widget.color),
          const SizedBox(width: 8),
          Text(widget.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                  letterSpacing: 0.5)),
        ]),
        if (widget.selectedProducts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selectedProducts
                .map((p) => _buildChip(p))
                .toList(),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _addFreeText(),
              decoration: InputDecoration(
                hintText: 'Search or type a product...',
                hintStyle: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.25)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _searchController,
            builder: (_, __) => _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: _addFreeText,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Add',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.color)),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ]),
        if (_showDropdown) ...[
          const SizedBox(height: 8),
          if (_results.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF12122a),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: _results.asMap().entries.map((entry) {
                  final i = entry.key;
                  final product = entry.value;
                  final alreadySelected =
                      widget.selectedProducts.contains(product.name);
                  return GestureDetector(
                    onTap: alreadySelected ? null : () => _selectProduct(product.name),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? const Radius.circular(12) : Radius.zero,
                          bottom: i == _results.length - 1
                              ? const Radius.circular(12)
                              : Radius.zero,
                        ),
                        color: alreadySelected
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.transparent,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(product.category,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: widget.color,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: alreadySelected
                                            ? Colors.white.withValues(alpha: 0.3)
                                            : Colors.white)),
                                Text(product.brand,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withValues(alpha: 0.4))),
                              ]),
                        ),
                        Text(product.priceRange,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.3))),
                        if (alreadySelected) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_rounded,
                              size: 12,
                              color: widget.color.withValues(alpha: 0.5)),
                        ],
                      ]),
                    ),
                  );
                }).toList(),
              ),
            )
          else if (_searchController.text.length > 2)
            GestureDetector(
              onTap: _addFreeText,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: widget.color.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.add_rounded, size: 14, color: widget.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'Add "${_searchController.text.trim()}"',
                        style: TextStyle(
                            fontSize: 12,
                            color: widget.color,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
        ],
      ]),
    );
  }

  Widget _buildChip(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(name,
            style: TextStyle(
                fontSize: 11,
                color: widget.color,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _removeProduct(name),
          child: Icon(Icons.close_rounded, size: 13, color: widget.color),
        ),
      ]),
    );
  }
}
