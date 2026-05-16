// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_activecampaign_suppression.dart';

const _tracerName = 'dartastic_otel_libs_activecampaign';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class ActivecampaignResult {
  const ActivecampaignResult({
    this.itemCount,
    this.total,
    this.entity,
    this.automationStatus,
    this.campaignStatus,
    this.dealValueMinor,
    this.currency,
    this.tier,
    this.account,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `meta.total`.
  final int? total;

  /// `contact` / `deal` / `automation` / `campaign` / `list` / `tag` /
  /// `account` / `task` / `ecomCustomer`.
  final String? entity;

  /// `1` (active) / `2` (inactive) / `3` (completed) — automation.
  final String? automationStatus;

  /// `0` (draft) / `1` (scheduled) / `2` (sending) / `5` (sent) /
  /// `6` (disabled) — campaign send state.
  final String? campaignStatus;

  /// Deal value in minor units.
  final int? dealValueMinor;

  /// ISO 4217.
  final String? currency;

  /// `lite` / `plus` / `professional` / `enterprise`.
  final String? tier;

  /// Customer account subdomain (`acme.api-us1.com`).
  final String? account;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class ActivecampaignCallResult<T> {
  const ActivecampaignCallResult({required this.value, this.result});
  final T value;
  final ActivecampaignResult? result;
}

/// Wraps an ActiveCampaign API call in a CLIENT span. [operation] is
/// one of `contacts.list`, `contacts.get`, `contacts.create`,
/// `contacts.update`, `contacts.add_tag`, `deals.list`, `deals.create`,
/// `deals.update`, `automations.list`, `automations.contacts.add`,
/// `automations.contacts.remove`, `campaigns.list`, `campaigns.send`,
/// `lists.list`, `tags.list`, `accounts.list`, `webhooks.create`,
/// `ecomCustomers.list`, `ecomOrders.create`.
Future<T> tracedActivecampaign<T>({
  required String operation,
  required Future<ActivecampaignCallResult<T>> Function() invoke,
  String? account,
}) async {
  if (activecampaignInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'activecampaign',
    'rpc.method': operation,
    'activecampaign.operation': operation,
  };
  if (account != null) m['activecampaign.account'] = account;

  final span = _tracer().startSpan(
    'activecampaign $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'activecampaign.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.total != null) {
        extras.add(OTel.attributeInt(
          'activecampaign.total',
          r.result!.total!,
        ));
      }
      if (r.result!.entity != null) {
        extras.add(OTel.attributeString(
          'activecampaign.entity',
          r.result!.entity!,
        ));
      }
      if (r.result!.automationStatus != null) {
        extras.add(OTel.attributeString(
          'activecampaign.automation.status',
          r.result!.automationStatus!,
        ));
      }
      if (r.result!.campaignStatus != null) {
        extras.add(OTel.attributeString(
          'activecampaign.campaign.status',
          r.result!.campaignStatus!,
        ));
      }
      if (r.result!.dealValueMinor != null) {
        extras.add(OTel.attributeInt(
          'activecampaign.deal.value.minor',
          r.result!.dealValueMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'activecampaign.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.tier != null) {
        extras.add(OTel.attributeString(
          'activecampaign.tier',
          r.result!.tier!,
        ));
      }
      if (r.result!.account != null) {
        extras.add(OTel.attributeString(
          'activecampaign.account',
          r.result!.account!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'activecampaign.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'ActiveCampaign HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
