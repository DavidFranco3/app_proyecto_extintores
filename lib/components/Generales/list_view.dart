import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DataTableCustom extends StatefulWidget {
  final List<Map<String, dynamic>> datos;
  final List<Map<String, dynamic>> columnas;
  final Widget Function(Map<String, dynamic>)? accionesBuilder;

  const DataTableCustom({
    super.key,
    required this.datos,
    required this.columnas,
    this.accionesBuilder,
  });

  @override
  State<DataTableCustom> createState() => _DataTableCustomState();
}

class _DataTableCustomState extends State<DataTableCustom> {
  // State for filtering, sorting and pagination
  String _searchQuery = '';
  String? _sortColumn;
  bool _sortAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    // 1. Filter Data
    List<Map<String, dynamic>> filteredData = widget.datos.where((row) {
      if (_searchQuery.isEmpty) return true;
      // Search in all columns
      return widget.columnas.any((col) {
        final val = row[col['name']]?.toString().toLowerCase() ?? '';
        return val.contains(_searchQuery.toLowerCase());
      });
    }).toList();

    // 2. Sort Data
    if (_sortColumn != null) {
      filteredData.sort((a, b) {
        final valA = a[_sortColumn]?.toString().toLowerCase() ?? '';
        final valB = b[_sortColumn]?.toString().toLowerCase() ?? '';
        return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      });
    }

    // 3. Pagination Logic
    final totalItems = filteredData.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    // Clamping page
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < totalItems)
        ? startIndex + _itemsPerPage
        : totalItems;

    // Data to show on current page
    final currentData = (startIndex < totalItems)
        ? filteredData.sublist(startIndex, endIndex)
        : <Map<String, dynamic>>[];

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Column(
        children: [
          // Header: Search & Sort Controls
          _buildHeader(),

          // List Body
          if (filteredData.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No se encontraron registros',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Scroll handled by parent usually
              itemCount: currentData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = currentData[index];
                return _buildRowCard(row);
              },
            ),

          // Footer: Pagination
          if (totalPages > 1) _buildPaginationFooter(totalPages, totalItems),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 1; // Reset to first page on search
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Sort Menu
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(FontAwesomeIcons.arrowDownShortWide,
                      color: Colors.blueAccent),
                ),
                onSelected: (colName) {
                  setState(() {
                    if (_sortColumn == colName) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortColumn = colName;
                      _sortAscending = true;
                    }
                  });
                },
                itemBuilder: (context) {
                  return widget.columnas.map<PopupMenuEntry<String>>((col) {
                    final name = col['name'].toString();
                    return PopupMenuItem<String>(
                      value: name,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name),
                          if (_sortColumn == name)
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: Colors.blueAccent,
                            ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowCard(Map<String, dynamic> row) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: Border.all(
                color: Colors.transparent), // Quita borde del expansion tile
            collapsedShape: Border.all(color: Colors.transparent),
            // Use first column as title
            title: Row(
              children: [
                // Indicator strip
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.columnas.isNotEmpty)
                        Text(
                          row[widget.columnas.first['name']]?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      if (widget.columnas.length > 1)
                        Text(
                          row[widget.columnas[1]['name']]?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.all(20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              // Detail list inside
              ...widget.columnas.skip(2).map((col) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${col['name']}:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row[col['name']]?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (widget.accionesBuilder != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: widget.accionesBuilder!(row),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(int totalPages, int totalItems) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: $totalItems',
            style:
                TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: Colors.blueAccent,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                color: Colors.blueAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
