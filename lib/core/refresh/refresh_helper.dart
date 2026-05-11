import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/new_domain_state.dart';
import '../../services/credential_state.dart';
import 'refresh_core.dart';

class RefreshHelper {
  static Future<void> refreshDomainListManual(BuildContext context) async {
    final credentialState = context.read<CredentialState>();
    final domainState = context.read<NewDomainState>();
    final selected = credentialState.selectedCredential;
    if (selected != null) {
      await domainState.refreshDomainList(
        providerId: selected.providerId,
        credentials: selected.credentials,
        triggerType: RefreshTriggerType.manual,
      );
    }
  }

  static Future<void> refreshDomainListPassive(BuildContext context) async {
    final credentialState = context.read<CredentialState>();
    final domainState = context.read<NewDomainState>();
    final selected = credentialState.selectedCredential;
    if (selected != null) {
      await domainState.refreshDomainList(
        providerId: selected.providerId,
        credentials: selected.credentials,
        triggerType: RefreshTriggerType.passive,
        animationType: RefreshAnimationType.centerLoading,
      );
    }
  }

  static Future<void> refreshDomainListPassiveWithCredential(
    BuildContext context, {
    required String providerId,
    required Map<String, String> credentials,
  }) async {
    final domainState = context.read<NewDomainState>();
    await domainState.refreshDomainList(
      providerId: providerId,
      credentials: credentials,
      triggerType: RefreshTriggerType.passive,
      animationType: RefreshAnimationType.centerLoading,
    );
  }

  static Future<void> refreshDnsRecordListManual(
    BuildContext context, {
    required String domainId,
  }) async {
    final credentialState = context.read<CredentialState>();
    final domainState = context.read<NewDomainState>();
    final selected = credentialState.selectedCredential;
    if (selected != null) {
      await domainState.refreshDnsRecordList(
        providerId: selected.providerId,
        domainId: domainId,
        credentials: selected.credentials,
        triggerType: RefreshTriggerType.manual,
      );
    }
  }

  static Future<void> refreshDnsRecordListPassive(
    BuildContext context, {
    required String domainId,
  }) async {
    final credentialState = context.read<CredentialState>();
    final domainState = context.read<NewDomainState>();
    final selected = credentialState.selectedCredential;
    if (selected != null) {
      await domainState.refreshDnsRecordList(
        providerId: selected.providerId,
        domainId: domainId,
        credentials: selected.credentials,
        triggerType: RefreshTriggerType.passive,
        animationType: RefreshAnimationType.centerLoading,
      );
    }
  }

  static Future<void> refreshDnsRecordListPassiveWithCredential(
    BuildContext context, {
    required String providerId,
    required String domainId,
    required Map<String, String> credentials,
  }) async {
    final domainState = context.read<NewDomainState>();
    await domainState.refreshDnsRecordList(
      providerId: providerId,
      domainId: domainId,
      credentials: credentials,
      triggerType: RefreshTriggerType.passive,
      animationType: RefreshAnimationType.centerLoading,
    );
  }
}