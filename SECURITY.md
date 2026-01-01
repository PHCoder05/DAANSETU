# Security Policy

## Supported Versions

Use this section to tell people about which versions of your project are currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of DAANSETU seriously. If you discover a security vulnerability, please follow these steps:

1.  **Do NOT open a public issue.** Publicly reporting a vulnerability can put user data at risk.
2.  **Email us immediately** at **security@daansetu.org**.
3.  Include a detailed description of the vulnerability, steps to reproduce it, and any potential impact.
4.  Our security team will acknowledge your report within 48 hours.
5.  We will work with you to triage and fix the issue.
6.  Once fixed and released, we will publicly acknowledge your contribution (with your permission).

## Security Best Practices

We follow industry-standard security practices:
- **JWT Authentication** for all API endpoints.
- **Input Validation** using `express-validator`.
- **Rate Limiting** to prevent abuse.
- **Environment Variables** for all secrets (never committed to git).
- **Helmet.js** for secure HTTP headers.

## Thank You

Thank you for helping keep DAANSETU safe for everyone!
