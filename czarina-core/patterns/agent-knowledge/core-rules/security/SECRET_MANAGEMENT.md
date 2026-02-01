# Secret Management

## Overview

Secret management is the secure handling of sensitive credentials including API keys, passwords, encryption keys, tokens, and certificates. Proper secret management prevents unauthorized access, data breaches, and credential theft. This document outlines security best practices for managing secrets in agent systems, extracted from production implementations in SARK and thesymposium.

## Core Principles

### Never Hardcode Secrets
- **No Secrets in Code**: Never commit credentials to version control
- **Environment Variables**: Store secrets in environment variables or secret managers
- **Configuration Files**: Use .env files (excluded from version control)
- **Runtime Injection**: Inject secrets at runtime, not build time

### Encrypt at Rest
- **Encrypted Storage**: Encrypt secrets before storing in databases
- **Symmetric Encryption**: Use AES-128 (Fernet) or AES-256
- **Key Management**: Protect encryption keys with environment variables or KMS

### Minimize Exposure
- **Scope Limitation**: Grant minimal required access duration and scope
- **Secret Rotation**: Regularly rotate credentials
- **Audit Logging**: Track all secret access and usage
- **Automatic Expiration**: Set expiration dates for temporary credentials

### Defense in Depth
- **Secret Scanning**: Detect accidentally exposed secrets
- **Access Controls**: Restrict who can access secrets
- **Network Isolation**: Separate secret management from application networks
- **Monitoring**: Alert on unusual secret access patterns

## Environment Variables

### Configuration Management

**Best Practices** (from `/home/jhenry/Source/sark/.env.example`):

```bash
# ============================================================================
# Application Settings
# ============================================================================
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

# ============================================================================
# PostgreSQL Database Configuration
# ============================================================================
POSTGRES_ENABLED=true
POSTGRES_MODE=external
POSTGRES_HOST=postgres.example.com
POSTGRES_PORT=5432
POSTGRES_DB=sark_production
POSTGRES_USER=sark_app_user
POSTGRES_PASSWORD=your_secure_password_here  # Use strong password
POSTGRES_SSL_MODE=require

# ============================================================================
# Valkey (Redis) Cache Configuration
# ============================================================================
VALKEY_ENABLED=true
VALKEY_MODE=external
VALKEY_HOST=redis.example.com
VALKEY_PORT=6379
VALKEY_PASSWORD=your_redis_password_here
VALKEY_SSL=true

# ============================================================================
# Kong API Gateway Authentication
# ============================================================================
KONG_ENABLED=true
KONG_ADMIN_API_KEY=your_kong_admin_key_here
```

**Key Recommendations**:

1. **Use .env.example as Template**:
   - Commit `.env.example` with placeholder values
   - Add `.env` to `.gitignore`
   - Document all required environment variables

2. **Strong Password Requirements**:
   - Minimum 16 characters for production
   - Mix of uppercase, lowercase, numbers, special characters
   - Never use default or example passwords

3. **SSL/TLS Configuration**:
   - Enable SSL for database connections (`POSTGRES_SSL_MODE=require`)
   - Enable SSL for Redis/Valkey (`VALKEY_SSL=true`)
   - Use TLS 1.2+ minimum

4. **Environment Separation**:
   ```bash
   # Development
   ENVIRONMENT=development
   DEBUG=true

   # Staging
   ENVIRONMENT=staging
   DEBUG=false

   # Production
   ENVIRONMENT=production
   DEBUG=false
   ```

### Loading Environment Variables

**Python Implementation**:

```python
import os
from pydantic import BaseSettings, Field

class Settings(BaseSettings):
    """Application settings loaded from environment"""

    # Application
    environment: str = Field(default="development", env="ENVIRONMENT")
    debug: bool = Field(default=False, env="DEBUG")

    # Database
    postgres_host: str = Field(..., env="POSTGRES_HOST")
    postgres_port: int = Field(default=5432, env="POSTGRES_PORT")
    postgres_user: str = Field(..., env="POSTGRES_USER")
    postgres_password: str = Field(..., env="POSTGRES_PASSWORD")
    postgres_db: str = Field(..., env="POSTGRES_DB")
    postgres_ssl_mode: str = Field(default="require", env="POSTGRES_SSL_MODE")

    # Secret Key (JWT signing)
    secret_key: str = Field(..., env="SECRET_KEY", min_length=32)

    # Encryption
    encryption_key: str = Field(..., env="ENCRYPTION_KEY")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False

def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
```

**Validation Rules**:
- Required fields raise error if missing
- `min_length=32` ensures sufficient entropy for secrets
- Type validation (int, bool, str) prevents configuration errors

## Encryption at Rest

### Fernet (AES-128) Encryption

**Use Case**: Encrypt API keys, tokens, and credentials before database storage

**Implementation** (from `/home/jhenry/Source/thesymposium/backend/services/encryption.py`):

```python
from cryptography.fernet import Fernet
from loguru import logger

class KeyEncryption:
    """Handle encryption/decryption of sensitive data (API keys, tokens)"""

    def __init__(self, encryption_key: Optional[str] = None):
        """
        Initialize encryption handler

        Args:
            encryption_key: 32-byte base64 encoded key from ENCRYPTION_KEY env var
        """
        if encryption_key:
            self.key = encryption_key.encode() if isinstance(encryption_key, str) else encryption_key
        else:
            # Get from environment or generate new one
            env_key = os.getenv("ENCRYPTION_KEY")
            if env_key:
                self.key = env_key.encode()
            else:
                # Generate new key (should only happen in dev/test)
                self.key = Fernet.generate_key()
                logger.warning("⚠️ Generated new encryption key - not persisted!")

        self.cipher = Fernet(self.key)
        logger.info("🔐 Encryption handler initialized")

    def encrypt(self, plaintext: str) -> str:
        """
        Encrypt a string value (e.g., API key)

        Returns:
            Base64 encoded encrypted value
        """
        if isinstance(plaintext, str):
            plaintext = plaintext.encode()

        encrypted = self.cipher.encrypt(plaintext)
        return encrypted.decode()  # Return as string

    def decrypt(self, encrypted_value: str) -> str:
        """
        Decrypt an encrypted value

        Returns:
            Decrypted plaintext string
        """
        if isinstance(encrypted_value, str):
            encrypted_value = encrypted_value.encode()

        decrypted = self.cipher.decrypt(encrypted_value)
        return decrypted.decode()

    @staticmethod
    def generate_key() -> str:
        """
        Generate a new encryption key

        Returns:
            Base64 encoded Fernet key
        """
        return Fernet.generate_key().decode()
```

**Usage Example**:

```python
from services.encryption import KeyEncryption

# Initialize with environment key
encryption = KeyEncryption()

# Encrypt API key before storage
api_key_plaintext = "sk-proj-abc123..."
api_key_encrypted = encryption.encrypt(api_key_plaintext)

# Store encrypted key in database
await db.save_api_key(
    user_id=user_id,
    provider="openai",
    encrypted_key=api_key_encrypted,
)

# Decrypt when needed
encrypted_key = await db.get_api_key(user_id, "openai")
api_key_plaintext = encryption.decrypt(encrypted_key)

# Use decrypted key for API call
response = await openai.call(api_key=api_key_plaintext)
```

**Security Best Practices**:

1. **Key Generation**:
   ```bash
   # Generate encryption key
   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

   # Add to .env
   ENCRYPTION_KEY=your_generated_key_here
   ```

2. **Key Storage**:
   - Store encryption key in environment variables
   - Use AWS KMS, Azure Key Vault, or HashiCorp Vault for production
   - Never commit encryption keys to version control

3. **Key Rotation**:
   - Rotate encryption keys annually or when compromised
   - Support dual-key decryption during rotation period
   - Re-encrypt all data with new key

4. **Database Schema**:
   ```sql
   CREATE TABLE api_keys (
       id UUID PRIMARY KEY,
       user_id UUID NOT NULL,
       provider VARCHAR(50) NOT NULL,
       encrypted_key TEXT NOT NULL,  -- Fernet encrypted value
       created_at TIMESTAMP NOT NULL,
       last_used TIMESTAMP,
       expires_at TIMESTAMP
   );
   ```

## Secret Scanning

### Detecting Exposed Secrets

**Use Case**: Prevent accidental secret exposure in logs, responses, or outputs

**Implementation** (from `/home/jhenry/Source/sark/src/sark/security/secret_scanner.py`):

```python
class SecretScanner:
    """Scan tool responses for accidentally exposed secrets"""

    # Secret detection patterns (pattern, name, confidence)
    SECRET_PATTERNS: list[tuple[str, str, float]] = [
        # API Keys
        (r"sk-[a-zA-Z0-9]{20,}", "OpenAI API Key", 1.0),
        (r"sk-proj-[a-zA-Z0-9\-_]{20,}", "OpenAI Project API Key", 1.0),
        (r"ghp_[a-zA-Z0-9]{20,}", "GitHub Personal Access Token", 1.0),
        (r"gho_[a-zA-Z0-9]{20,}", "GitHub OAuth Token", 1.0),
        (r"github_pat_[a-zA-Z0-9_]{82}", "GitHub Fine-Grained PAT", 1.0),
        (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID", 1.0),
        (r"AIza[0-9A-Za-z\-_]{35}", "Google API Key", 0.95),
        (r"xox[baprs]-[0-9a-zA-Z]{10,48}", "Slack Token", 1.0),

        # Private Keys
        (r"-----BEGIN[ A-Z]*PRIVATE KEY-----", "Private Key (PEM)", 1.0),
        (r"-----BEGIN RSA PRIVATE KEY-----", "RSA Private Key", 1.0),
        (r"-----BEGIN EC PRIVATE KEY-----", "EC Private Key", 1.0),
        (r"-----BEGIN OPENSSH PRIVATE KEY-----", "OpenSSH Private Key", 1.0),

        # JWT Tokens
        (r"eyJ[a-zA-Z0-9_\-]+\.eyJ[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+", "JWT Token", 0.9),

        # Database Connection Strings
        (r"(?i)(postgres|mysql|mongodb)://[^:]+:[^@]+@[^/]+", "Database Connection String", 0.95),

        # Provider-Specific
        (r"sk_live_[0-9a-zA-Z]{24,}", "Stripe Secret Key", 1.0),
        (r"SK[0-9a-fA-F]{32}", "Twilio API Key", 0.85),
        (r"sk-ant-[a-zA-Z0-9\-_]{70,}", "Anthropic API Key", 1.0),

        # Base64 Encoded Secrets (potential)
        (
            r"(?:[A-Za-z0-9+/]{4}){16,}(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?",
            "Potential Base64 Secret",
            0.5,
        ),
    ]

    # Patterns that should never be redacted (false positive reduction)
    FALSE_POSITIVE_PATTERNS = [
        r"127\.0\.0\.1",
        r"0\.0\.0\.0",
        r"test@test\.com",
        r"(?i)dummy",
        r"(?i)sample",
        r"(?i)placeholder",
    ]

    def scan(self, data: dict[str, Any]) -> list[SecretFinding]:
        """
        Scan data for exposed secrets

        Args:
            data: Dictionary to scan (typically tool response)

        Returns:
            List of secret findings
        """
        findings = []

        # Batch candidate strings
        candidates = [
            (loc, val)
            for loc, val in self._flatten_dict_generator(data, min_str_len=16)
            if self._could_contain_secret(val)
        ]

        # Scan all candidates
        for location, value in candidates:
            findings.extend(self._scan_value(value, location))

        return findings

    def redact_secrets(
        self, data: dict[str, Any], findings: list[SecretFinding] | None = None
    ) -> dict[str, Any]:
        """
        Redact secrets from data

        Args:
            data: Data to redact
            findings: Optional pre-computed findings

        Returns:
            Redacted copy of data
        """
        if findings is None:
            findings = self.scan(data)

        if not findings:
            return data

        # Deep copy to avoid modifying original
        redacted = copy.deepcopy(data)

        # Redact each finding
        for finding in findings:
            if finding.should_redact:
                redacted = self._redact_location(
                    redacted, finding.location, finding._full_match
                )

        return redacted
```

**Usage Example**:

```python
from sark.security.secret_scanner import SecretScanner

scanner = SecretScanner()

# Scan tool response for secrets
tool_response = {
    "status": "success",
    "data": {
        "api_key": "sk-proj-abc123def456...",  # Will be detected
        "message": "Configuration loaded"
    }
}

# Detect secrets
findings = scanner.scan(tool_response)

if findings:
    # Log security event
    logger.warning(
        "secrets_detected",
        count=len(findings),
        types=[f.secret_type for f in findings],
    )

    # Redact before logging or returning
    redacted_response = scanner.redact_secrets(tool_response, findings)

    # Log redacted version
    logger.info("tool_response", data=redacted_response)
```

**Supported Secret Types**:
- OpenAI API keys (sk-, sk-proj-)
- GitHub tokens (ghp_, gho_, github_pat_)
- AWS access keys (AKIA...)
- Google API keys (AIza...)
- Slack tokens (xox...)
- Private keys (PEM, RSA, EC, OpenSSH)
- JWT tokens
- Database connection strings
- Stripe keys (sk_live_)
- Twilio keys
- Anthropic keys (sk-ant-)
- Base64 encoded secrets

## Secret Rotation

### API Key Rotation Strategy

**Rotation Frequency**:
- **Critical Secrets**: Every 30 days
- **High-Sensitivity**: Every 90 days
- **Standard Secrets**: Every 180 days
- **Development Secrets**: As needed

**Rotation Process**:

1. **Generate New Secret**:
   ```python
   # Generate new API key
   new_api_key = secrets.token_urlsafe(32)
   new_key_hash = hashlib.sha256(new_api_key.encode()).hexdigest()
   ```

2. **Dual-Key Period** (Grace Period):
   ```python
   # Support both old and new keys during transition
   async def validate_api_key(plain_key: str) -> APIKey | None:
       # Check new key first
       if new_key := await db.get_key_by_hash(hash_key(plain_key)):
           if new_key.is_active:
               return new_key

       # Fall back to old key during grace period
       if old_key := await db.get_old_key_by_hash(hash_key(plain_key)):
           if old_key.expires_at > datetime.now():
               # Log warning - old key still in use
               logger.warning("old_api_key_used", key_id=old_key.key_id)
               return old_key

       return None
   ```

3. **Notify Users**:
   ```python
   await send_rotation_notification(
       user_email=user.email,
       key_name=api_key.name,
       rotation_deadline=datetime.now() + timedelta(days=7),
   )
   ```

4. **Revoke Old Secret**:
   ```python
   # After grace period, revoke old key
   async def complete_rotation(old_key_id: UUID):
       await db.update_key(old_key_id, is_active=False)
       logger.info("api_key_rotated", old_key_id=old_key_id)
   ```

### Session Secret Rotation

**Session Secret** (from thesymposium):

```bash
# Generate session secret
openssl rand -hex 32

# Add to .env
SESSION_SECRET=your_generated_session_secret_here
```

**Rotation Impact**:
- All existing sessions invalidated
- Users must re-authenticate
- Schedule rotation during maintenance windows

## Secrets in CI/CD

### GitHub Actions

**Storing Secrets**:

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Production
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          SECRET_KEY: ${{ secrets.SECRET_KEY }}
          ENCRYPTION_KEY: ${{ secrets.ENCRYPTION_KEY }}
        run: |
          ./deploy.sh
```

**Best Practices**:
- Use GitHub repository secrets (Settings → Secrets and variables → Actions)
- Use environment-specific secrets
- Enable secret scanning in repository settings
- Never log secret values (GitHub redacts known patterns)

### Docker Secrets

**docker-compose.yml**:

```yaml
version: '3.8'

services:
  app:
    image: sark:latest
    secrets:
      - database_password
      - secret_key
      - encryption_key
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/database_password
      SECRET_KEY_FILE: /run/secrets/secret_key
      ENCRYPTION_KEY_FILE: /run/secrets/encryption_key

secrets:
  database_password:
    file: ./secrets/database_password.txt
  secret_key:
    file: ./secrets/secret_key.txt
  encryption_key:
    file: ./secrets/encryption_key.txt
```

**Reading Docker Secrets**:

```python
def get_secret(secret_name: str, env_var: str) -> str:
    """Load secret from Docker secret file or environment variable"""
    secret_file = os.getenv(f"{env_var}_FILE")

    if secret_file and os.path.exists(secret_file):
        with open(secret_file) as f:
            return f.read().strip()

    return os.getenv(env_var)

# Usage
database_password = get_secret("database_password", "POSTGRES_PASSWORD")
```

## Cloud Secret Management

### AWS Secrets Manager

```python
import boto3
from botocore.exceptions import ClientError

def get_secret(secret_name: str, region_name: str = "us-east-1") -> dict:
    """Retrieve secret from AWS Secrets Manager"""
    client = boto3.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        response = client.get_secret_value(SecretId=secret_name)
        return json.loads(response['SecretString'])
    except ClientError as e:
        logger.error("secret_retrieval_failed", error=str(e))
        raise

# Usage
secrets = get_secret("sark/production/database")
db_password = secrets["password"]
```

### HashiCorp Vault

```python
import hvac

def get_vault_secret(path: str) -> dict:
    """Retrieve secret from HashiCorp Vault"""
    client = hvac.Client(
        url=os.getenv("VAULT_ADDR"),
        token=os.getenv("VAULT_TOKEN"),
    )

    # Read secret
    response = client.secrets.kv.v2.read_secret_version(
        path=path,
        mount_point="secret",
    )

    return response["data"]["data"]

# Usage
db_secrets = get_vault_secret("database/production")
db_password = db_secrets["password"]
```

## What NOT to Do

### Anti-Patterns

1. **Hardcoded Credentials**:
   ```python
   # ❌ NEVER DO THIS
   DATABASE_URL = "postgresql://user:password123@db.example.com/prod"
   API_KEY = "sk-proj-abc123def456..."
   ```

2. **Secrets in Version Control**:
   ```bash
   # ❌ NEVER COMMIT
   git add .env
   git commit -m "Add configuration"
   ```

3. **Secrets in Logs**:
   ```python
   # ❌ NEVER LOG SECRETS
   logger.info(f"Using API key: {api_key}")

   # ✅ REDACT INSTEAD
   logger.info(f"Using API key: {api_key[:8]}...")
   ```

4. **Secrets in URLs**:
   ```python
   # ❌ NEVER PUT SECRETS IN URLs
   url = f"https://api.example.com/data?api_key={api_key}"

   # ✅ USE HEADERS
   headers = {"Authorization": f"Bearer {api_key}"}
   response = requests.get("https://api.example.com/data", headers=headers)
   ```

5. **Secrets in Error Messages**:
   ```python
   # ❌ NEVER EXPOSE IN ERRORS
   raise Exception(f"Auth failed with key: {api_key}")

   # ✅ GENERIC ERROR
   raise HTTPException(status_code=401, detail="Authentication failed")
   ```

6. **Unencrypted Transmission**:
   ```python
   # ❌ NEVER SEND OVER HTTP
   requests.post("http://api.example.com/auth", json={"password": pwd})

   # ✅ USE HTTPS
   requests.post("https://api.example.com/auth", json={"password": pwd})
   ```

## Secret Management Checklist

- [ ] Store all secrets in environment variables or secret managers
- [ ] Add `.env` to `.gitignore`
- [ ] Provide `.env.example` with placeholder values
- [ ] Encrypt secrets at rest using Fernet or AES-256
- [ ] Use strong encryption keys (256 bits minimum)
- [ ] Implement secret scanning in CI/CD pipelines
- [ ] Redact secrets from logs and error messages
- [ ] Rotate secrets regularly (30-180 days based on sensitivity)
- [ ] Use SSL/TLS for all secret transmission
- [ ] Enable secret scanning on GitHub repositories
- [ ] Audit secret access and usage
- [ ] Implement least privilege for secret access
- [ ] Use cloud secret managers (AWS Secrets Manager, Vault) in production
- [ ] Test secret rotation procedures
- [ ] Document secret recovery procedures
- [ ] Monitor for exposed secrets in public repositories
- [ ] Revoke secrets immediately when compromised

## References

- **SARK .env.example**: `/home/jhenry/Source/sark/.env.example`
- **thesymposium Encryption**: `/home/jhenry/Source/thesymposium/backend/services/encryption.py`
- **SARK Secret Scanner**: `/home/jhenry/Source/sark/src/sark/security/secret_scanner.py`
- **OWASP Secrets Management**: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- **Cryptography Library**: https://cryptography.io/
- **HashiCorp Vault**: https://www.vaultproject.io/

## Next Steps

- Review **AUTHENTICATION.md** for securing authentication secrets
- Review **INJECTION_PREVENTION.md** for preventing secret extraction
- Review **AUDIT_LOGGING.md** for tracking secret access
