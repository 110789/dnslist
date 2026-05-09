import '../../models/entities/domain_entity.dart';
import '../../models/entities/dns_record_entity.dart';

class DomainService {
  DomainService._();

  static DomainService? _instance;

  static DomainService get instance {
    _instance ??= DomainService._();
    return _instance!;
  }

  Future<List<DomainEntity>> getDomains(String provider, {int page = 1, int pageSize = 20}) async {
    return [];
  }

  Future<List<DnsRecordEntity>> getDnsRecords(String provider, String domainId, {int page = 1, int pageSize = 20}) async {
    return [];
  }

  Future<DnsRecordEntity> createDnsRecord(String provider, String domainId, DnsRecordEntity record) async {
    return record;
  }

  Future<DnsRecordEntity> updateDnsRecord(String provider, String domainId, DnsRecordEntity record) async {
    return record;
  }

  Future<void> deleteDnsRecord(String provider, String domainId, String recordId) async {}
}