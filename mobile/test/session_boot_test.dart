import 'package:flutter_test/flutter_test.dart';
import 'package:mallika_hospitals/core/api/api_exception.dart';
import 'package:mallika_hospitals/core/api/auth_api.dart';
import 'package:mallika_hospitals/core/session/session_controller.dart';
import 'package:mallika_hospitals/core/session/token_store.dart';

void main() {
  test('a network failure keeps the saved session', () async {
    final store = MemoryTokenStore();
    await store.write(TokenStore.refreshKey, 'saved-refresh');
    final session = SessionController(api: _FailingRefresh(0), tokens: store);

    await session.boot();

    expect(session.gate, Gate.unreachable);
    expect(await store.read(TokenStore.refreshKey), 'saved-refresh');
  });

  test('a rejected refresh token clears the saved session', () async {
    final store = MemoryTokenStore();
    await store.write(TokenStore.refreshKey, 'saved-refresh');
    await store.write(TokenStore.accessKey, 'saved-access');
    final session = SessionController(api: _FailingRefresh(401), tokens: store);

    await session.boot();

    expect(session.gate, Gate.signedOut);
    expect(await store.read(TokenStore.refreshKey), isNull);
    expect(await store.read(TokenStore.accessKey), isNull);
  });
}

class _FailingRefresh extends AuthApi {
  _FailingRefresh(this.statusCode);

  final int statusCode;

  @override
  Future<VerifiedSession> refresh(String refreshToken) async {
    throw ApiException(
      statusCode: statusCode,
      code: statusCode == 401 ? 'AUTHENTICATION_REQUIRED' : 'NETWORK',
      message: statusCode == 401
          ? 'Authentication is required.'
          : 'The hospital service could not be reached.',
    );
  }
}
