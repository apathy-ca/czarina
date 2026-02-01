# Authentication Security

## Overview

Authentication is the process of verifying the identity of users, services, and agents before granting access to resources. This document outlines security best practices for implementing robust authentication mechanisms in agent systems, extracted from production implementations in SARK and thesymposium.

## Core Principles

### Defense in Depth
- **Multiple Authentication Methods**: Support JWT, API keys, sessions, and OAuth/OIDC
- **Layered Validation**: Validate at multiple points (gateway, middleware, service)
- **Fail Secure**: Default to denial when authentication fails or is uncertain

### Zero Trust
- **Verify Every Request**: Never assume authentication based on previous requests
- **Short-Lived Credentials**: Use expiration times to limit exposure windows
- **Explicit Validation**: Always validate tokens, sessions, and credentials

### Least Privilege
- **Scoped Permissions**: Grant minimal required access through scopes
- **Role-Based Access**: Assign roles with specific permission sets
- **Time-Limited Access**: Enforce token expiration and session timeouts

## Authentication Methods

### 1. JWT (JSON Web Tokens)

**Use Cases**: User authentication, API access, service-to-service communication

**Implementation** (from `/home/jhenry/Source/sark/src/sark/services/auth/jwt.py:22-94`):

```python
class JWTHandler:
    """Handles JWT token creation and validation."""

    def __init__(
        self,
        secret_key: str | None = None,
        algorithm: str = "HS256",
        access_token_expire_minutes: int = 30,
        refresh_token_expire_days: int = 7,
    ) -> None:
        self.secret_key = secret_key or settings.secret_key
        self.algorithm = algorithm
        self.access_token_expire_minutes = access_token_expire_minutes
        self.refresh_token_expire_days = refresh_token_expire_days

    def create_access_token(
        self,
        user_id: UUID,
        email: str,
        role: str,
        teams: list[str] | None = None,
        extra_claims: dict[str, Any] | None = None,
    ) -> str:
        now = datetime.now(UTC)
        expire = now + timedelta(minutes=self.access_token_expire_minutes)

        claims = {
            "sub": str(user_id),
            "email": email,
            "role": role,
            "teams": teams or [],
            "iat": now,
            "exp": expire,
            "type": "access",
        }

        if extra_claims:
            claims.update(extra_claims)

        return jwt.encode(claims, self.secret_key, algorithm=self.algorithm)
```

**Security Best Practices**:

1. **Algorithm Selection**:
   - Use `HS256` (HMAC-SHA256) for symmetric signing
   - Use `RS256` (RSA-SHA256) for asymmetric signing in distributed systems
   - Never use `none` algorithm

2. **Token Expiration**:
   - **Access tokens**: 15-30 minutes
   - **Refresh tokens**: 7 days maximum
   - Always include `exp` (expiration) and `iat` (issued at) claims

3. **Token Types**:
   - Separate access and refresh token types
   - Validate token type during verification (from `jwt.py:153-158`):
   ```python
   if payload.get("type") != "access":
       raise HTTPException(
           status_code=status.HTTP_401_UNAUTHORIZED,
           detail="Invalid token type",
       )
   ```

4. **Claims Structure**:
   - **sub**: User ID (UUID string)
   - **email**: User email address
   - **role**: User role (ADMIN, USER, SERVICE)
   - **teams**: List of team identifiers
   - **type**: Token type (access, refresh)
   - **iat**: Issued at timestamp
   - **exp**: Expiration timestamp

5. **Token Validation** (from `jwt.py:132-168`):
   ```python
   def decode_token(self, token: str) -> dict[str, Any]:
       try:
           payload = jwt.decode(
               token,
               self.secret_key,
               algorithms=[self.algorithm],
           )

           # Verify token type
           if payload.get("type") != "access":
               raise HTTPException(
                   status_code=status.HTTP_401_UNAUTHORIZED,
                   detail="Invalid token type",
               )

           return payload

       except JWTError as e:
           logger.warning("token_validation_failed", error=str(e))
           raise HTTPException(
               status_code=status.HTTP_401_UNAUTHORIZED,
               detail="Could not validate credentials",
           )
   ```

6. **Secret Key Management**:
   - Minimum 32 characters/256 bits
   - Store in environment variables, never in code
   - Rotate keys periodically
   - Use different keys for different environments

**Usage in FastAPI Routes**:

```python
from fastapi import Depends
from sark.services.auth.jwt import get_current_user

@router.get("/protected")
async def protected_route(user: UserContext = Depends(get_current_user)):
    return {"user_id": user.user_id, "role": user.role}
```

### 2. API Keys

**Use Cases**: Service-to-service authentication, programmatic access, automation

**Implementation** (from `/home/jhenry/Source/sark/src/sark/services/auth/api_key.py:33-132`):

```python
class APIKeyService:
    """Service for managing API keys."""

    def generate_key(self) -> str:
        """Generate a secure API key using cryptographic randomness."""
        return secrets.token_urlsafe(32)  # 256 bits of entropy

    def hash_key(self, api_key: str) -> str:
        """Hash an API key for storage using SHA256."""
        import hashlib
        return hashlib.sha256(api_key.encode()).hexdigest()

    def verify_key(self, plain_key: str, key_hash: str) -> bool:
        """Verify an API key against its hash."""
        return self.hash_key(plain_key) == key_hash

    def create_api_key(
        self,
        name: str,
        owner_id: UUID,
        scopes: list[str] | None = None,
        description: str | None = None,
        expires_in_days: int | None = None,
    ) -> tuple[str, APIKey]:
        plain_key = self.generate_key()
        key_hash = self.hash_key(plain_key)

        api_key = APIKey(
            key_id=uuid4(),
            key_hash=key_hash,
            name=name,
            owner_id=owner_id,
            scopes=scopes or [],
            expires_at=datetime.now(UTC) + timedelta(days=expires_in_days) if expires_in_days else None,
        )

        return plain_key, api_key
```

**Security Best Practices**:

1. **Key Generation**:
   - Use `secrets.token_urlsafe()` for cryptographic randomness
   - Minimum 32 bytes (256 bits) of entropy
   - Never use predictable patterns or timestamps

2. **Key Storage**:
   - **Never store plain text keys** in database
   - Hash keys using SHA256 or better
   - Store only the hash for verification
   - Show plain key only once during creation

3. **Key Scoping**:
   ```python
   def has_scope(self, api_key: APIKey, required_scope: str) -> bool:
       """Check if API key has required scope."""
       return required_scope in api_key.scopes or "*" in api_key.scopes
   ```
   - Define specific scopes (e.g., `servers:read`, `servers:write`, `servers:delete`)
   - Use wildcard `*` only for administrative keys
   - Validate scopes on every request

4. **Key Expiration**:
   ```python
   if api_key.expires_at and datetime.now(UTC) > api_key.expires_at:
       raise HTTPException(
           status_code=status.HTTP_401_UNAUTHORIZED,
           detail="API key has expired",
       )
   ```
   - Set expiration dates for all keys
   - Enforce expiration checks before validation
   - Provide key rotation mechanisms

5. **Key Metadata**:
   - Track `created_at`, `last_used_at`, `is_active` fields
   - Log all key usage for audit trails
   - Support key revocation via `is_active` flag

**Usage in FastAPI Routes**:

```python
from fastapi import Depends, Security
from sark.services.auth.api_key import get_api_key, require_scope

@router.delete("/servers/{server_id}")
async def delete_server(
    server_id: UUID,
    api_key: APIKey = Depends(require_scope("servers:delete")),
):
    # Key has been validated and has required scope
    pass
```

### 3. Session Management

**Use Cases**: Web applications, browser-based authentication, persistent login

**Implementation** (from `/home/jhenry/Source/sark/src/sark/services/auth/session.py:28-96`):

```python
class SessionService:
    """Service for managing user sessions."""

    def __init__(
        self,
        session_lifetime_hours: int = 24,
        max_sessions_per_user: int = 5,
    ):
        self.session_lifetime_hours = session_lifetime_hours
        self.max_sessions_per_user = max_sessions_per_user

    def generate_session_id(self) -> str:
        """Generate a secure session ID."""
        return secrets.token_urlsafe(32)

    def create_session(
        self,
        user_id: UUID,
        user_agent: str | None = None,
        ip_address: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> Session:
        now = datetime.now(UTC)
        expires_at = now + timedelta(hours=self.session_lifetime_hours)

        return Session(
            session_id=self.generate_session_id(),
            user_id=user_id,
            created_at=now,
            expires_at=expires_at,
            last_accessed_at=now,
            user_agent=user_agent,
            ip_address=ip_address,
            metadata=metadata or {},
            is_active=True,
        )
```

**Security Best Practices**:

1. **Session ID Generation**:
   - Use cryptographically secure random generator (`secrets.token_urlsafe()`)
   - Minimum 256 bits of entropy
   - Never use sequential or predictable IDs

2. **Session Lifetime**:
   - Default: 24 hours for web applications
   - Maximum: 7 days for "remember me" functionality
   - Implement both idle timeout and absolute timeout

3. **Session Refresh** (from `session.py:121-146`):
   ```python
   def refresh_session(self, session: Session) -> Session:
       """Refresh session on activity (sliding window)."""
       self.validate_session(session)

       now = datetime.now(UTC)
       session.last_accessed_at = now
       session.expires_at = now + timedelta(hours=self.session_lifetime_hours)

       return session
   ```

4. **Session Metadata Tracking**:
   - `user_agent`: Detect session hijacking
   - `ip_address`: Detect suspicious location changes
   - `created_at`: Track session age
   - `last_accessed_at`: Implement idle timeout

5. **Session Storage**:
   - Use Redis or similar fast key-value store for production
   - Enable session cleanup for expired sessions:
   ```python
   def cleanup_expired(self) -> int:
       """Remove expired sessions."""
       now = datetime.now(UTC)
       expired = [
           sid for sid, session in self._sessions.items()
           if now > session.expires_at
       ]
       for session_id in expired:
           self.delete(session_id)
       return len(expired)
   ```

6. **Concurrent Session Limits**:
   - Limit sessions per user (default: 5)
   - Track all user sessions for bulk invalidation
   - Support "logout all devices" functionality

**Cookie Security** (from thesymposium):

```python
# Set secure session cookie
response.set_cookie(
    key="session_token",
    value=session_id,
    httponly=True,        # Prevents JavaScript access (XSS protection)
    secure=True,          # HTTPS only in production
    samesite="lax",       # CSRF protection
    max_age=86400,        # 24 hours in seconds
    path="/",             # Application-wide
)
```

### 4. OAuth 2.0 / OpenID Connect

**Use Cases**: Third-party authentication, SSO (Single Sign-On), federated identity

**Implementation** (from `/home/jhenry/Source/sark/src/sark/services/auth/providers/oidc.py:29-246`):

```python
class OIDCProvider(AuthProvider):
    """OpenID Connect authentication provider."""

    async def get_authorization_url(
        self,
        state: str,
        redirect_uri: str,
        nonce: str | None = None,
    ) -> str:
        """Generate OIDC authorization URL."""
        discovery = await self._get_discovery_document()
        authorization_endpoint = discovery["authorization_endpoint"]

        # Generate nonce if not provided
        if not nonce:
            nonce = secrets.token_urlsafe(32)

        params = {
            "client_id": self.config.client_id,
            "response_type": "code",
            "scope": " ".join(self.config.scopes),  # openid profile email
            "redirect_uri": redirect_uri,
            "state": state,
            "nonce": nonce,
        }

        return f"{authorization_endpoint}?{urlencode(params)}"

    async def handle_callback(
        self,
        code: str,
        state: str,
        redirect_uri: str,
    ) -> dict[str, Any] | None:
        """Exchange authorization code for tokens."""
        discovery = await self._get_discovery_document()
        token_endpoint = discovery["token_endpoint"]

        async with httpx.AsyncClient() as client:
            response = await client.post(
                token_endpoint,
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "client_id": self.config.client_id,
                    "client_secret": self.config.client_secret,
                    "redirect_uri": redirect_uri,
                },
            )

            if response.status_code != 200:
                return None

            return response.json()  # access_token, id_token, refresh_token
```

**Security Best Practices**:

1. **CSRF Protection via State Parameter** (from thesymposium `/home/jhenry/Source/thesymposium/backend/services/auth_service.py:135-170`):
   ```python
   # Generate state for CSRF protection
   state = secrets.token_urlsafe(32)

   # Store state in Redis with 5-minute expiration
   await redis.setex(f"oauth_state:{state}", 300, "pending")

   # Verify state in callback
   stored_state = await redis.get(f"oauth_state:{state}")
   if not stored_state:
       raise ValueError("Invalid or expired state parameter")

   # Delete used state (single use)
   await redis.delete(f"oauth_state:{state}")
   ```

2. **PKCE (Proof Key for Code Exchange)**:
   - Generate code verifier: `secrets.token_urlsafe(32)`
   - Create code challenge: `base64(sha256(code_verifier))`
   - Include in authorization request
   - Validate in token exchange

3. **Scope Management**:
   - Request minimal required scopes
   - Standard scopes: `openid`, `profile`, `email`
   - Additional scopes: `read_user`, `read_api` (provider-specific)

4. **Token Validation**:
   - Verify ID token signature using provider's public keys
   - Validate issuer (`iss`) matches expected provider
   - Validate audience (`aud`) matches client ID
   - Check expiration (`exp`) and not-before (`nbf`) claims
   - Verify nonce matches original request

5. **Discovery Document Caching**:
   ```python
   async def _get_discovery_document(self) -> dict[str, Any]:
       """Fetch and cache OIDC discovery document."""
       if self._discovery_cache:
           return self._discovery_cache

       discovery_url = f"{issuer_url}/.well-known/openid-configuration"
       # Fetch and cache
       self._discovery_cache = response.json()
       return self._discovery_cache
   ```

6. **Session Fixation Prevention**:
   - Generate new session ID after successful authentication
   - Invalidate any pre-authentication session
   - Never reuse session IDs

## Multi-Factor Authentication (MFA)

**Implementation** (from `/home/jhenry/Source/sark/src/sark/security/mfa.py`):

**Supported Methods**:
- **TOTP** (Time-based One-Time Password): RFC 6238 compliant
- **SMS**: Text message verification codes
- **Email**: Email verification codes
- **Push**: Push notification approval

**TOTP Best Practices**:

1. **Setup Flow**:
   - Generate secret key using cryptographic random generator
   - Display QR code for authenticator app enrollment
   - Require user to verify code before enabling MFA
   - Provide backup codes for account recovery

2. **Verification**:
   - Accept codes within time window (±30 seconds for drift tolerance)
   - Implement rate limiting (max 3-5 attempts)
   - Lock account after excessive failures
   - Log all MFA verification attempts

3. **Backup Codes**:
   - Generate 8-10 single-use backup codes
   - Hash codes before storage
   - Invalidate after use
   - Allow regeneration with MFA verification

## Common Authentication Vulnerabilities

### 1. Credential Stuffing

**Mitigation**:
- Implement rate limiting per IP and per user
- Use CAPTCHA after failed attempts
- Monitor for suspicious login patterns
- Enforce strong password policies
- Support MFA to mitigate compromised credentials

### 2. Session Hijacking

**Mitigation**:
- Bind sessions to IP address and user agent
- Use secure, HttpOnly, SameSite cookies
- Implement session fingerprinting
- Detect and alert on suspicious session activity
- Support remote session revocation

### 3. Token Theft

**Mitigation**:
- Use short-lived access tokens (15-30 minutes)
- Implement token rotation for refresh tokens
- Bind tokens to specific clients when possible
- Monitor for token reuse from different IPs
- Support token revocation lists

### 4. Brute Force Attacks

**Mitigation**:
- Rate limit authentication attempts
- Implement progressive delays after failures
- Lock accounts after threshold (e.g., 5 failures)
- Log all failed authentication attempts
- Alert on distributed brute force attempts

## Authentication Checklist

- [ ] Use cryptographically secure random generators for all tokens/sessions
- [ ] Implement short expiration times for access tokens (15-30 minutes)
- [ ] Store only hashed API keys, never plain text
- [ ] Validate token type (access vs refresh) during verification
- [ ] Use HTTPS for all authentication endpoints
- [ ] Implement CSRF protection for OAuth flows (state parameter)
- [ ] Set secure cookie flags (HttpOnly, Secure, SameSite)
- [ ] Log all authentication events (success and failure)
- [ ] Implement rate limiting on authentication endpoints
- [ ] Support MFA for sensitive operations
- [ ] Provide session management UI (view/revoke active sessions)
- [ ] Implement session cleanup for expired sessions
- [ ] Use environment variables for secrets, never hardcode
- [ ] Rotate authentication secrets periodically
- [ ] Test authentication error handling and edge cases

## References

- **SARK JWT Implementation**: `/home/jhenry/Source/sark/src/sark/services/auth/jwt.py`
- **SARK API Key Service**: `/home/jhenry/Source/sark/src/sark/services/auth/api_key.py`
- **SARK Session Management**: `/home/jhenry/Source/sark/src/sark/services/auth/session.py`
- **SARK OIDC Provider**: `/home/jhenry/Source/sark/src/sark/services/auth/providers/oidc.py`
- **thesymposium Auth Service**: `/home/jhenry/Source/thesymposium/backend/services/auth_service.py`
- **OWASP Authentication Cheat Sheet**: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- **RFC 6749**: OAuth 2.0 Authorization Framework
- **RFC 7519**: JSON Web Token (JWT)
- **RFC 6238**: TOTP - Time-Based One-Time Password Algorithm

## Next Steps

- Review **AUTHORIZATION.md** for implementing access control and permissions
- Review **SECRET_MANAGEMENT.md** for storing authentication credentials securely
- Review **AUDIT_LOGGING.md** for tracking authentication events
