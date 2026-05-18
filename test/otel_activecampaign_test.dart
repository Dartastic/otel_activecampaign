// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_activecampaign/otel_activecampaign.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_activecampaign-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('campaigns.send records campaign + tier + account', () async {
    await tracedActivecampaign<String>(
      operation: 'campaigns.send',
      account: 'acme.api-us1.com',
      invoke: () async => const ActivecampaignCallResult(
        value: 'ok',
        result: ActivecampaignResult(
          entity: 'campaign',
          campaignStatus: '2',
          tier: 'professional',
          account: 'acme.api-us1.com',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('activecampaign campaigns.send')!);
    expect(a['activecampaign.entity'], 'campaign');
    expect(a['activecampaign.campaign.status'], '2');
    expect(a['activecampaign.tier'], 'professional');
    expect(a['activecampaign.account'], 'acme.api-us1.com');
  });

  test('suppression skips spans', () async {
    await runWithoutActivecampaignInstrumentationAsync(() async {
      await tracedActivecampaign<String>(
        operation: 'contacts.list',
        invoke: () async => const ActivecampaignCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('activecampaign '), isEmpty);
  });
}
