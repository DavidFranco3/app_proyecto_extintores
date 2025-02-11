import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';

class DataTableCustom extends StatefulWidget {
  final List<Map<String, dynamic>> datos;
  final List<Map<String, dynamic>> columnas;
  final bool hiddenOptions;

  DataTableCustom({
    required this.datos,
    required this.columnas,
    this.hiddenOptions = false,
  });

  @override
  _DataTableCustomState createState() => _DataTableCustomState();
}

class _DataTableCustomState extends State<DataTableCustom> {
  TextEditingController _filterController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];
  List<String> _visibleColumns = [];

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.datos);
    _visibleColumns =
        widget.columnas.map((col) => col['name'] as String).toList();
  }

  void handleFilterChange(String value) {
    setState(() {
      if (value.isEmpty) {
        _filteredData = List.from(widget.datos);
      } else {
        _filteredData = widget.datos.where((row) {
          return row.values.any((v) {
            if (v != null) {
              return v.toString().toLowerCase().contains(value.toLowerCase());
            }
            return false;
          });
        }).toList();
      }
    });
  }

  void handleColumnVisibilityChange(String columnName) {
    setState(() {
      if (_visibleColumns.contains(columnName)) {
        _visibleColumns.remove(columnName);
      } else {
        _visibleColumns.add(columnName);
      }
    });
  }

  void showColumnSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Mostrar Columnas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.columnas.map((col) {
                    return CheckboxListTile(
                      title: Text(col['name']),
                      value: _visibleColumns.contains(col['name']),
                      onChanged: (bool? value) {
                        if (value != null) {
                          setDialogState(() {
                            handleColumnVisibilityChange(col['name']);
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Table Custom')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.hiddenOptions)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _filterController,
                      onChanged: handleFilterChange,
                      decoration: InputDecoration(
                        labelText: 'Buscar...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.visibility),
                    onPressed: showColumnSelectionDialog,
                  ),
                ],
              ),
            ),
          Expanded(
            // Asegura que el Swiper ocupe el espacio restante
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                final row = _filteredData[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _visibleColumns.map((columnName) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(
                                '${columnName}: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  row[columnName]?.toString() ?? '',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              itemCount: _filteredData.length,
              pagination: SwiperPagination(),
              control: SwiperControl(),
            ),
          ),
        ],
      ),
    );
  }
}
