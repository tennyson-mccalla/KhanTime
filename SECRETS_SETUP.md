# KhanTime Secrets Setup Guide

## ⚠️ IMPORTANT: Security First

This project uses sensitive API credentials. Follow these steps carefully to ensure they remain secure.

## Initial Setup

1. **Copy the credentials template:**
   ```bash
   cp Source/Utilities/Credentials.swift.template Source/Utilities/Credentials.swift
   ```

2. **Edit the new file** with your actual credentials:
   - Client ID: Get from Alpha/TimeBack team
   - Client Secret: Get from Alpha/TimeBack team
   - Environment: Choose `staging` or `production`

3. **Verify `.gitignore` is working:**
   ```bash
   git status
   # Credentials.swift should NOT appear in the output
   ```

## Getting Credentials

Contact the Alpha/TimeBack team for credentials:
- Carlos Bonetti (carlos@ae.studio)
- Wellington Santos (wellington.santos@ae.studio)
- Felipe Taboada (felipe@ae.studio)

Specify:
- Which environment (staging/production)
- Your use case (KhanTime MVP)

## API Endpoints

The [Alpha 1EdTech API](https://api.alpha-1edtech.com/scalar) provides:
- **Staging GraphQL**: https://api.staging.alpha-1edtech.com/scalar
- **Production GraphQL**: https://api.alpha-1edtech.com/scalar

## Security Best Practices

### Never Commit Secrets
- ✅ Use `.gitignore` (already configured)
- ✅ Use template files for examples
- ❌ Never hardcode credentials in commits
- ❌ Never share credentials in issues/PRs

### For Production Apps
Consider these more secure approaches:
1. **iOS Keychain Services** - Store credentials encrypted on device
2. **Environment Variables** - For CI/CD pipelines
3. **Remote Configuration** - Firebase Remote Config, AWS Secrets Manager
4. **Certificate Pinning** - For additional API security

## Verification Checklist

Before committing:
- [ ] Run `git status` - no Credentials.swift visible
- [ ] Run `git diff --cached` - no secrets in staged files
- [ ] Search codebase for hardcoded values: `grep -r "3ab5g0ak4fshvlaccu0s9f75g" .`
- [ ] Verify `.gitignore` includes `Credentials.swift`

## If Secrets Are Accidentally Committed

1. **Immediately** revoke the compromised credentials
2. Request new credentials from the Alpha team
3. Use `git filter-branch` or BFG Repo-Cleaner to remove from history
4. Force push the cleaned history
5. Notify all team members to re-clone

## Environment-Specific Setup

### Staging (Development)
- Base URL: `https://api.staging.alpha-1edtech.com`
- Auth URL: `https://alpha-auth-development-idp.auth.us-west-2.amazoncognito.com`
- Use for development and testing

### Production
- Base URL: `https://api.alpha-1edtech.com`
- Auth URL: `https://alpha-auth-production-idp.auth.us-west-2.amazoncognito.com`
- Use only for production releases

## Questions?

If you need help with credentials or security setup, please contact the project maintainers.
