import 'dart:async';

import '../data/models.dart';

abstract class PrinterService {
  Future<void> printTicket(ProductionTicket ticket);
}

class ConsolePrinterService implements PrinterService {
  @override
  Future<void> printTicket(ProductionTicket ticket) async {
    // Simulate some latency while "printing".
    await Future.delayed(const Duration(milliseconds: 200));
    // In a real implementation, this would talk to a platform channel.
  }
}
