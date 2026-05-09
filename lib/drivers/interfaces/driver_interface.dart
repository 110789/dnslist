import 'package:flutter/widgets.dart';

import '../../models/entities/domain_entity.dart';
import '../../models/entities/dns_record_entity.dart';
import '../../models/entities/credential_entity.dart';

abstract class DriverInterface {
  String get providerName;

  Future<bool> validateCredential(CredentialEntity credential);

  Future<List<DomainEntity>> getDomains({int page = 1, int pageSize = 20});

  Future<List<DnsRecordEntity>> getDnsRecords(String domainId, {int page = 1, int pageSize = 20});

  Future<DnsRecordEntity> createDnsRecord(String domainId, DnsRecordEntity record);

  Future<DnsRecordEntity> updateDnsRecord(String domainId, DnsRecordEntity record);

  Future<void> deleteDnsRecord(String domainId, String recordId);

  Widget buildDomainListItem(DomainEntity domain);

  Widget buildDnsRecordListItem(DnsRecordEntity record);
}