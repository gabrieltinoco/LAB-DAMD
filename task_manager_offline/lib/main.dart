import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'services/database_service.dart';
import 'services/sync_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Offline First Demo', home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SyncService _syncService = SyncService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _controller = TextEditingController();

  bool _isOnline = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _syncService.initialize();
    _refreshList();

    // Escuta mudanças na conexão para atualizar a UI (Cor da AppBar)
    _syncService.connectivityStream.listen((results) {
      setState(() {
        _isOnline = !results.contains(ConnectivityResult.none);
      });
      // Se voltou a ficar online, atualiza a lista após processar a fila
      if (_isOnline) {
        Future.delayed(Duration(seconds: 2), _refreshList);
      }
    });
  }

  void _refreshList() async {
    final data = await _dbService.getItems();
    setState(() {
      _items = data;
    });
  }

  void _addItem() async {
    if (_controller.text.isNotEmpty) {
      await _syncService.addItem(_controller.text);
      _controller.clear();
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOnline ? "Modo Online 🟢" : "Modo Offline 🔴"),
        backgroundColor: _isOnline ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Novo Item"),
                  ),
                ),
                IconButton(icon: Icon(Icons.add), onPressed: _addItem),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSynced = item['is_synced'] == 1;

                return ListTile(
                  title: Text(item['title']),
                  subtitle: Text(item['id']),
                  trailing: Icon(
                    isSynced ? Icons.check_circle : Icons.cloud_off,
                    color: isSynced ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
