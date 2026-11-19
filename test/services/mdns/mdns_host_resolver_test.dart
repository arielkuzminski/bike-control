import 'dart:io';

import 'package:bike_control/services/mdns/mdns_host_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop/mdns/dns_message.dart';

void main() {
  late RawDatagramSocket responder;
  final questions = <DnsQuestion>[];

  Future<void> startResponder(List<DnsRecord> Function(DnsQuery query) answer) async {
    responder = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    responder.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = responder.receive();
      if (datagram == null) return;
      final query = parseDnsQuery(datagram.data)!;
      questions.addAll(query.questions);
      final answers = answer(query);
      if (answers.isEmpty) return;
      responder.send(
        buildDnsResponse(id: query.id, answers: answers),
        datagram.address,
        datagram.port,
      );
    });
  }

  setUp(questions.clear);
  tearDown(() => responder.close());

  test('resolves a hostname whose label contains a space', () async {
    await startResponder(
      (query) => [dnsA(query.questions.single.name, [192, 168, 129, 58])],
    );

    final address = await MdnsHostResolver.resolveIPv4(
      'ELITE-JUSTO 2-01090-W.local',
      target: InternetAddress.loopbackIPv4,
      port: responder.port,
    );

    expect(address, '192.168.129.58');
    final question = questions.first;
    expect(question.name, ['ELITE-JUSTO 2-01090-W', 'local']);
    expect(question.type, dnsTypeA);
    expect(question.unicastResponse, isTrue);
  });

  test('ignores answers for other names', () async {
    await startResponder(
      (_) => [dnsA(dnsNameFromString('Other.local'), [10, 0, 0, 1])],
    );

    final address = await MdnsHostResolver.resolveIPv4(
      'KICKR.local',
      target: InternetAddress.loopbackIPv4,
      port: responder.port,
      timeout: const Duration(milliseconds: 400),
    );

    expect(address, isNull);
  });

  test('gives up after the timeout when nothing answers', () async {
    await startResponder((_) => []);

    final address = await MdnsHostResolver.resolveIPv4(
      'KICKR.local',
      target: InternetAddress.loopbackIPv4,
      port: responder.port,
      timeout: const Duration(milliseconds: 400),
    );

    expect(address, isNull);
    expect(questions, isNotEmpty);
  });
}
