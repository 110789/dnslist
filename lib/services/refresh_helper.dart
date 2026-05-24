import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/refresh/refresh_core.dart';
import '../core/refresh/refresh_types.dart';
import '../utils/log/log.dart';
import 'new_domain_state.dart';
import 'credential_state.dart';

class RefreshHelper {
  static Future<void> refreshDomainListManual(BuildContext context) async {
    LogService.instance.info(
      module: 'ux',
      className: 'RefreshHelper',
      methodName: 'refreshDomainListManual',
      action: '用户触发下拉刷新',
      status: 'pending',
    );
    final credentialState = context.read<CredentialState>();
    final domainState = context.read<NewDomainState>();
    final selected = credentialState.selectedCredential;
    if (selected != null) {
      await domainState.refreshDomainList(
        providerId: selected.providerId,
        credentials: selected.credentials,
        triggerType: RefreshTriggerType.manual,
      );
      LogService.instance.info(
        module: 'ux',
        className: 'RefreshHelper',
        methodName: 'refreshDomainListManual',
        action: '下拉刷新完成',
        data: {'providerId': selected.providerId, 'triggerType': 'manual'},
        status: 'success',
      );
    }
  }

  static Future<void> refreshDomainListPassive(BuildContext context) async {
    final credentialState = context.read<CredentialState>();
    final domainState = context.read<NewDomainState>();
    final selected = credentialState.selectedCredential;
    if (selected != null) {
      LogService.instance.debug(
        module: 'ux',
        className: 'RefreshHelper',
        methodName: 'refreshDomainListPassive',
        action: '被动刷新触发',
        data: {'providerId': selected.providerId},
      );
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
    LogService.instance.debug(
      module: 'ux',
      className: 'RefreshHelper',
      methodName: 'refreshDomainListPassiveWithCredential',
      action: '凭证切换后刷新',
      data: {'providerId': providerId},
    );
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
