# Quick Pattern Reference

A handy reference for common regex patterns to use with Data::Random::String::Matches.

## Table of Contents

- [Numbers](#numbers)
- [Letters](#letters)
- [Mixed Alphanumeric](#mixed-alphanumeric)
- [Identifiers](#identifiers)
- [Contact Information](#contact-information)
- [Financial](#financial)
- [Passwords](#passwords)
- [Codes & References](#codes--references)
- [Web & URLs](#web--urls)
- [Technical](#technical)
- [Dates & Times](#dates--times)

---

## Numbers

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{4}` | 4-digit number | 1234 |
| `\d{6}` | 6-digit number | 123456 |
| `[1-9]\d{3}` | 4-digit, no leading zero | 5432 |
| `\d{3}-\d{3}-\d{4}` | Phone format | 555-123-4567 |
| `\d{5}` | ZIP code | 12345 |
| `\d{5}-\d{4}` | ZIP+4 | 12345-6789 |

## Letters

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Z]{3}` | 3 uppercase letters | ABC |
| `[a-z]{5}` | 5 lowercase letters | hello |
| `[A-Z][a-z]{4}` | Title case word | Hello |
| `[a-z]{3,8}` | 3-8 lowercase letters | word |

## Mixed Alphanumeric

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Za-z0-9]{8}` | 8 mixed chars | aB3cD9eF |
| `[A-Z0-9]{6}` | 6 uppercase + digits | A1B2C3 |
| `[A-Z]{3}\d{4}` | 3 letters + 4 digits | ABC1234 |
| `\w{10}` | 10 word chars | aB3_cD9eF_ |

## Identifiers

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `AIza[0-9A-Za-z_-]{35}` | Google API key style | AIzaSyB1c2D3e4F5g6H7i8J9k0L1m2N3o4P5 |
| `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}` | UUID v4 | 550e8400-e29b-41d4-a716-446655440000 |
| `[0-9a-f]{7}` | Git short hash | a1b2c3d |
| `[A-Z]{3}\d{10}` | Database ID | ABC1234567890 |
| `[A-Za-z0-9]{32}` | Session token | aB3cD9eFgH1iJ2kL3mN4oP5qR6sT7uV8 |

## Contact Information

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{3}-\d{3}-\d{4}` | US Phone | 555-123-4567 |
| `\+1-\d{3}-\d{3}-\d{4}` | US Phone (intl) | +1-555-123-4567 |
| `\(\d{3}\) \d{3}-\d{4}` | US Phone (formatted) | (555) 123-4567 |
| `[a-z]{5,10}@[a-z]{5,10}\.com` | Simple email | hello@world.com |
| `[a-z]{5,10}@(gmail\|yahoo\|hotmail)\.com` | Email with domains | user@gmail.com |
| `\d{5}` | US ZIP | 12345 |
| `[A-Z]{2} \d[A-Z] \d[A-Z]\d` | Canadian postal | K1A 0B1 |

## Financial

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `4\d{15}` | Visa test card | 4123456789012345 |
| `5[1-5]\d{14}` | Mastercard test | 5412345678901234 |
| `\d{4}-\d{4}-\d{4}-\d{4}` | Card formatted | 1234-5678-9012-3456 |
| `\d{3}` | CVV | 123 |
| `\d{10,12}` | Bank account | 1234567890 |
| `TXN[A-Z0-9]{12}` | Transaction ID | TXNA1B2C3D4E5F6 |

## Passwords

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Za-z0-9]{12}` | Simple 12-char | aB3cD9eFgH1i |
| `[A-Za-z0-9!@#$%^&*]{16}` | Strong 16-char | aB3!cD9@eFgH#1iJ |
| `[A-Z][a-z]{3}\d{4}` | Temp password | Pass1234 |
| `[a-z]{4,8}-[a-z]{4,8}-[a-z]{4,8}` | Passphrase | word-another-third |
| `[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}` | Recovery code | A1B2-C3D4-E5F6 |

## Codes & References

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `ORD-\d{8}` | Order number | ORD-12345678 |
| `INV-\d{4}-[A-Z]{3}` | Invoice number | INV-2024-ABC |
| `(SAVE\|DEAL\|SALE)\d{2}[A-Z]{3}` | Coupon code | SAVE10ABC |
| `[A-Z]{2}-\d{4}-[A-Z]{2}` | Product SKU | AB-1234-CD |
| `SN[A-Z0-9]{10}` | Serial number | SNA1B2C3D4E5 |
| `CONF-[A-Z0-9]{6}` | Confirmation | CONF-A1B2C3 |

## Web & URLs

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[a-z]{5,10}\.example\.com` | Subdomain | hello.example.com |
| `[A-Za-z0-9]{6}` | Short URL code | aB3cD9 |
| `[a-z]{3,8}\d{2,4}` | Username | user123 |
| `[a-z]{4,8}-[a-z]{4,8}` | URL slug | some-slug |
| `[a-z0-9]{8,16}` | Username (strict) | user1234 |

## Technical

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}` | IPv4 address | 192.168.1.1 |
| `[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}` | MAC address | 00:1A:2B:3C:4D:5E |
| `\d{1,2}\.\d{1,2}\.\d{1,3}` | Version number | 1.2.345 |
| `#[0-9A-F]{6}` | Hex color | #FF5733 |
| `[0-9a-f]{32}` | MD5 hash | 5d41402abc4b2a76b9719d911017c592 |
| `[0-9a-f]{40}` | SHA-1 hash | 356a192b7913b04c54574d18c28d46e6395428ab |

## Dates & Times

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `20\d{2}-(0[1-9]\|1[0-2])-(0[1-9]\|[12]\d\|3[01])` | Date YYYY-MM-DD | 2024-03-15 |
| `(0[1-9]\|1[0-2])/([0-2]\d\|3[01])/\d{4}` | Date MM/DD/YYYY | 03/15/2024 |
| `([01]\d\|2[0-3]):[0-5]\d` | Time HH:MM | 14:30 |
| `([01]\d\|2[0-3]):[