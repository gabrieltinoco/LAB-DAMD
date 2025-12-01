import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

class SyncService {
  final DatabaseService _dbService = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  // Stream para a UI saber se está online/offline
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  // Inicia o monitoramento
  void initialize() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Se tiver qualquer conexão que não seja 'none'
      if (!results.contains(ConnectivityResult.none)) {
        print("🟢 ONLINE DETECTADO - Iniciando Sincronização...");
        processQueue();
      } else {
        print("🔴 MODO OFFLINE");
      }
    });
  }

  // Processa a Fila (Sobe os dados para "Nuvem")
  Future<void> processQueue() async {
    final pending = await _dbService.getPendingSyncs();

    if (pending.isEmpty) return;

    for (var task in pending) {
      try {
        // SIMULAÇÃO DO ENVIO PARA API (POST/PUT)
        // No mundo real: await api.post('/items', data: ...);
        await Future.delayed(Duration(seconds: 1)); // Fake network delay

        print("Sincronizando item: ${task['payload']} (${task['operation']})");

        // Se deu sucesso:
        // 1. Remove da fila
        await _dbService.removeFromQueue(task['id']);
        // 2. Marca o item como 'check' (sincronizado) na tabela visual
        await _dbService.markAsSynced(task['item_id']);
      } catch (e) {
        print("Erro ao sincronizar: $e");
        // Se der erro, mantém na fila para tentar depois
      }
    }
    print("✅ Sincronização concluída!");
  }

  // Método chamado pela UI para adicionar item
  Future<void> addItem(String title) async {
    String id = Uuid().v4(); // Gera ID localmente
    await _dbService.insertItem(id, title);

    // Tenta sincronizar imediatamente se tiver net
    var connectivityResult = await _connectivity.checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      processQueue();
    }
  }
}
