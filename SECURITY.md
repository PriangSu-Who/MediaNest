# Security Policy

## Reporting a vulnerability

Please do not publish sensitive security details in a public issue.

For vulnerabilities involving MediaNest source code, installers, update mechanisms, argument handling, or bundled-component verification, contact the project maintainer privately through the GitHub repository owner account.

When reporting a vulnerability, include:

- A short description of the issue.
- The affected version or commit.
- Steps to reproduce, where safe to provide them.
- Expected and actual behavior.
- Any relevant logs or screenshots with personal information and credentials removed.

Do not include passwords, API keys, cookies, authentication tokens, or other secrets in a report.

## Scope

Security review should pay particular attention to:

- PowerShell and CMD argument handling.
- URLs and filenames containing shell metacharacters.
- Downloaded component integrity and SHA-256 verification.
- Update and repair mechanisms.
- Local file/path handling.
- Any future network or credential-related features.

## Supported versions

MediaNest is currently under active development. Until the first public release, there is no formal long-term support guarantee for older development builds.
