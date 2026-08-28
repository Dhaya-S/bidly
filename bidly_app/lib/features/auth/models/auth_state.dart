import 'user_model.dart';

enum AuthStatus { initial, unauthenticated, authenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? pendingMobile;
  final String? pendingName;
  final String? pendingRequestId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.pendingMobile,
    this.pendingName,
    this.pendingRequestId,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? pendingMobile,
    String? pendingName,
    String? pendingRequestId,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      pendingMobile: pendingMobile ?? this.pendingMobile,
      pendingName: pendingName ?? this.pendingName,
      pendingRequestId: pendingRequestId ?? this.pendingRequestId,
      errorMessage: errorMessage,
    );
  }
}
