import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/api/api_client.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/auth/token_store.dart';

/// Scripted HTTP adapter: a handler per request, recording every call.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<(int, Map<String, Object?>)> Function(RequestOptions) handler;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.add(options);
    final (status, json) = await handler(options);
    return ResponseBody.fromString(jsonEncode(json), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> ok(Object data) => {'success': true, 'data': data, 'error': null};
Map<String, Object?> fail(String code) => {
      'success': false,
      'data': null,
      'error': {'code': code, 'message': 'رسالة'},
    };

final me = {
  'id': 'u1',
  'email': 'a@b.co',
  'emailVerified': true,
  'role': 'student',
  'fullName': 'x',
  'educationLevelId': null,
};

Map<String, Object?> pair(String n) => {
      'accessToken': 'access-$n',
      'accessTokenExpiresAt': '2030-01-01T00:00:00.000Z',
      'refreshToken': 'refresh-$n',
      'refreshTokenExpiresAt': '2030-01-01T00:00:00.000Z',
    };

void main() {
  late MemoryTokenStore tokens;
  setUp(() async {
    tokens = MemoryTokenStore();
    await tokens.write(const StoredTokens(accessToken: 'access-0', refreshToken: 'refresh-0'));
  });

  ApiClient build(FakeAdapter adapter, {void Function()? expired, void Function()? update}) => ApiClient(
        baseUrl: 'http://api.test',
        tokens: tokens,
        platform: 'android',
        appVersion: '1.2.3',
        useCookies: false,
        onSessionExpired: expired,
        onUpdateRequired: update,
        adapter: adapter,
      );

  test('sends bearer, platform and version headers', () async {
    final adapter = FakeAdapter((_) async => (200, ok(me)));
    await build(adapter).api.me.getMe();
    final headers = adapter.calls.single.headers;
    expect(headers['Authorization'], 'Bearer access-0');
    expect(headers['X-App-Platform'], 'android');
    expect(headers['X-App-Version'], '1.2.3');
  });

  test('refreshes once for concurrent 401s, then retries with the new token', () async {
    var refreshes = 0;
    final adapter = FakeAdapter((o) async {
      if (o.path == '/api/v1/auth/mobile/refresh') {
        refreshes++;
        expect((o.data as Map)['refreshToken'], 'refresh-0');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return (200, ok(pair('1')));
      }
      return o.headers['Authorization'] == 'Bearer access-1' ? (200, ok(me)) : (401, fail('AUTH_SESSION_EXPIRED'));
    });
    final client = build(adapter);
    final results = await Future.wait([client.api.me.getMe(), client.api.me.getMe(), client.api.me.getMe()]);
    expect(results.map((r) => r.data.id), ['u1', 'u1', 'u1']);
    expect(refreshes, 1);
    expect((await tokens.read())!.refreshToken, 'refresh-1');
  });

  test('a rejected refresh clears tokens and reports the expired session', () async {
    var expired = false;
    final adapter = FakeAdapter((o) async => (401, fail('AUTH_SESSION_EXPIRED')));
    final client = build(adapter, expired: () => expired = true);
    await expectLater(
      guardApi(() => client.api.me.getMe()),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'AUTH_SESSION_EXPIRED')),
    );
    expect(expired, isTrue);
    expect(await tokens.read(), isNull);
  });

  test('a network failure during refresh keeps the tokens', () async {
    final adapter = FakeAdapter((o) async {
      if (o.path == '/api/v1/auth/mobile/refresh') {
        throw DioException.connectionError(requestOptions: o, reason: 'offline');
      }
      return (401, fail('AUTH_SESSION_EXPIRED'));
    });
    await expectLater(guardApi(() => build(adapter).api.me.getMe()), throwsA(isA<ApiException>()));
    expect(await tokens.read(), isNotNull);
  });

  test('APP_UPDATE_REQUIRED triggers the force-update callback', () async {
    var update = false;
    final adapter = FakeAdapter((_) async => (426, fail('APP_UPDATE_REQUIRED')));
    await expectLater(
      guardApi(() => build(adapter, update: () => update = true).api.me.getMe()),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'APP_UPDATE_REQUIRED')),
    );
    expect(update, isTrue);
  });
}
