enum AuthErrorCode {
  unexpectedFailure('unexpected_failure'),
  validationFailed('validation_failed'),
  badJson('bad_json'),
  emailExists('email_exists'),
  phoneExists('phone_exists'),
  badJwt('bad_jwt'),
  notAdmin('not_admin'),
  noAuthorization('no_authorization'),
  userNotFound('user_not_found'),
  sessionNotFound('session_not_found'),
  flowStateNotFound('flow_state_not_found'),
  flowStateExpired('flow_state_expired'),
  signupDisabled('signup_disabled'),
  userBanned('user_banned'),
  providerEmailNeedsVerification('provider_email_needs_verification'),
  inviteNotFound('invite_not_found'),
  badOauthState('bad_oauth_state'),
  badOauthCallback('bad_oauth_callback'),
  oauthProviderNotSupported('oauth_provider_not_supported'),
  unexpectedAudience('unexpected_audience'),
  singleIdentityNotDeletable('single_identity_not_deletable'),
  emailConflictIdentityNotDeletable('email_conflict_identity_not_deletable'),
  identityAlreadyExists('identity_already_exists'),
  emailProviderDisabled('email_provider_disabled'),
  phoneProviderDisabled('phone_provider_disabled'),
  tooManyEnrolledMfaFactors('too_many_enrolled_mfa_factors'),
  mfaFactorNameConflict('mfa_factor_name_conflict'),
  mfaFactorNotFound('mfa_factor_not_found'),
  mfaIpAddressMismatch('mfa_ip_address_mismatch'),
  mfaChallengeExpired('mfa_challenge_expired'),
  mfaVerificationFailed('mfa_verification_failed'),
  mfaVerificationRejected('mfa_verification_rejected'),
  insufficientAal('insufficient_aal'),
  captchaFailed('captcha_failed'),
  samlProviderDisabled('saml_provider_disabled'),
  manualLinkingDisabled('manual_linking_disabled'),
  smsSendFailed('sms_send_failed'),
  emailNotConfirmed('email_not_confirmed'),
  phoneNotConfirmed('phone_not_confirmed'),
  reauthNonceMissing('reauth_nonce_missing'),
  samlRelayStateNotFound('saml_relay_state_not_found'),
  samlRelayStateExpired('saml_relay_state_expired'),
  samlIdpNotFound('saml_idp_not_found'),
  samlAssertionNoUserId('saml_assertion_no_user_id'),
  samlAssertionNoEmail('saml_assertion_no_email'),
  userAlreadyExists('user_already_exists'),
  ssoProviderNotFound('sso_provider_not_found'),
  samlMetadataFetchFailed('saml_metadata_fetch_failed'),
  samlIdpAlreadyExists('saml_idp_already_exists'),
  ssoDomainAlreadyExists('sso_domain_already_exists'),
  samlEntityIdMismatch('saml_entity_id_mismatch'),
  conflict('conflict'),
  providerDisabled('provider_disabled'),
  userSsoManaged('user_sso_managed'),
  reauthenticationNeeded('reauthentication_needed'),
  samePassword('same_password'),
  reauthenticationNotValid('reauthentication_not_valid'),
  otpExpired('otp_expired'),
  otpDisabled('otp_disabled'),
  identityNotFound('identity_not_found'),
  weakPassword('weak_password'),
  overRequestRateLimit('over_request_rate_limit'),
  overEmailSendRateLimit('over_email_send_rate_limit'),
  overSmsSendRateLimit('over_sms_send_rate_limit'),
  badCodeVerifier('bad_code_verifier'),
  anonymousProviderDisabled('anonymous_provider_disabled'),
  hookTimeout('hook_timeout'),
  hookTimeoutAfterRetry('hook_timeout_after_retry'),
  hookPayloadOverSizeLimit('hook_payload_over_size_limit'),
  hookPayloadUnknownSize('hook_payload_unknown_size'),
  requestTimeout('request_timeout'),
  mfaPhoneEnrollDisabled('mfa_phone_enroll_not_enabled'),
  mfaPhoneVerifyDisabled('mfa_phone_verify_not_enabled'),
  mfaTotpEnrollDisabled('mfa_totp_enroll_not_enabled'),
  mfaTotpVerifyDisabled('mfa_totp_verify_not_enabled'),
  unknown('unknown');

  const AuthErrorCode(this.code);

  final String code;

  static AuthErrorCode fromCode(String? code) {
    if (code == null || code.isEmpty) {
      return AuthErrorCode.unknown;
    }
    for (final value in AuthErrorCode.values) {
      if (value.code == code) {
        return value;
      }
    }
    return AuthErrorCode.unknown;
  }

  String? get defaultMessage {
    switch (this) {
      case AuthErrorCode.emailExists:
      case AuthErrorCode.userAlreadyExists:
      case AuthErrorCode.identityAlreadyExists:
        return '이미 가입된 계정이 있습니다.\n로그인하거나 비밀번호를 재설정해주세요.';
      case AuthErrorCode.phoneExists:
        return '이미 등록된 전화번호입니다.';
      case AuthErrorCode.signupDisabled:
        return '현재 회원가입이 비활성화되어 있습니다.';
      case AuthErrorCode.userBanned:
        return '해당 계정은 이용이 제한되었습니다.';
      case AuthErrorCode.providerEmailNeedsVerification:
        return '이메일 인증이 필요합니다.\n받은 편지함을 확인해주세요.';
      case AuthErrorCode.emailProviderDisabled:
        return '이메일 인증 방식이 비활성화되어 있습니다.';
      case AuthErrorCode.phoneProviderDisabled:
        return '전화번호 인증 방식이 비활성화되어 있습니다.';
      case AuthErrorCode.tooManyEnrolledMfaFactors:
        return '등록 가능한 MFA 수를 초과했습니다.';
      case AuthErrorCode.mfaVerificationFailed:
      case AuthErrorCode.mfaVerificationRejected:
        return '다중 인증에 실패했습니다.\n다시 시도해주세요.';
      case AuthErrorCode.mfaChallengeExpired:
        return '다중 인증 시간이 초과되었습니다.';
      case AuthErrorCode.insufficientAal:
        return '요청한 보안 수준을 충족하지 못했습니다.';
      case AuthErrorCode.captchaFailed:
        return '자동 입력 방지 인증에 실패했습니다.';
      case AuthErrorCode.smsSendFailed:
        return '인증 문자 전송에 실패했습니다.\n잠시 후 다시 시도해주세요.';
      case AuthErrorCode.emailNotConfirmed:
        return '이메일 인증이 완료되지 않았습니다.';
      case AuthErrorCode.phoneNotConfirmed:
        return '전화번호 인증이 완료되지 않았습니다.';
      case AuthErrorCode.reauthNonceMissing:
        return '재인증 토큰이 존재하지 않습니다.';
      case AuthErrorCode.overRequestRateLimit:
        return '요청이 너무 많습니다.\n잠시 후 다시 시도해주세요.';
      case AuthErrorCode.overEmailSendRateLimit:
        return '이메일 발송 제한을 초과했습니다.\n잠시 후 다시 시도해주세요.';
      case AuthErrorCode.overSmsSendRateLimit:
        return '문자 발송 제한을 초과했습니다.\n잠시 후 다시 시도해주세요.';
      case AuthErrorCode.weakPassword:
        return '비밀번호가 보안 기준을 충족하지 않습니다.';
      case AuthErrorCode.samePassword:
        return '이전과 동일한 비밀번호는 사용할 수 없습니다.';
      case AuthErrorCode.otpExpired:
        return '인증 코드가 만료되었습니다.';
      case AuthErrorCode.otpDisabled:
        return '해당 인증 코드 방식은 비활성화되어 있습니다.';
      case AuthErrorCode.requestTimeout:
        return '요청 시간이 초과되었습니다.\n네트워크 상태를 확인해주세요.';
      case AuthErrorCode.unexpectedFailure:
        return '예상치 못한 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      case AuthErrorCode.validationFailed:
      case AuthErrorCode.badJson:
        return '요청 형식이 올바르지 않습니다.';
      case AuthErrorCode.badJwt:
        return '인증 토큰이 유효하지 않습니다.';
      case AuthErrorCode.notAdmin:
      case AuthErrorCode.noAuthorization:
        return '해당 작업에 대한 권한이 없습니다.';
      case AuthErrorCode.userNotFound:
      case AuthErrorCode.identityNotFound:
        return '해당 사용자를 찾을 수 없습니다.';
      default:
        return null;
    }
  }
}
