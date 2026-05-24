import 'dart:async';

enum ArchitectureEvent {
  domainListRefresh,
  dnsRecordRefresh,
  credentialChanged,
  themeChanged,
  domainOperationStart,
  domainOperationEnd,
  recordOperationStart,
  recordOperationEnd,
}

class ArchitectureEventBus {
  static ArchitectureEventBus? _instance;
  static ArchitectureEventBus get instance => _instance ??= ArchitectureEventBus._();

  ArchitectureEventBus._();

  final _controller = StreamController<ArchitectureEvent>.broadcast();

  Stream<ArchitectureEvent> get events => _controller.stream;

  void emit(ArchitectureEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

class DomainListRefreshEvent {
  final String? providerId;
  final RefreshTrigger trigger;

  const DomainListRefreshEvent({this.providerId, required this.trigger});
}

enum RefreshTrigger {
  manual,
  passive,
  auto,
}

class DnsRecordRefreshEvent {
  final String domainId;
  final RefreshTrigger trigger;

  const DnsRecordRefreshEvent({required this.domainId, required this.trigger});
}

class CredentialChangedEvent {
  final String? credentialId;

  const CredentialChangedEvent({this.credentialId});
}

class DomainOperationEvent {
  final String domainId;
  final OperationType type;
  final bool start;

  const DomainOperationEvent({
    required this.domainId,
    required this.type,
    required this.start,
  });
}

enum OperationType {
  create,
  update,
  delete,
  renew,
}

class RecordOperationEvent {
  final String domainId;
  final String recordId;
  final OperationType type;
  final bool start;

  const RecordOperationEvent({
    required this.domainId,
    required this.recordId,
    required this.type,
    required this.start,
  });
}