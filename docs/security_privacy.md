# Security & Privacy — Foundation v1

This repository is designed to be **portfolio-safe** and excludes sensitive information by default.

## What is included
- Database schema (DDL), views, and tests (`/sql`)
- Documentation (`/docs`)
- High-level descriptions of sources (store codes, modeling approach)

## What is NOT included
- Raw WooCommerce databases or backups
- CSV exports or extracts (orders, customers, products, etc.)
- Any credentials, API keys, tokens, or `.env` files
- Any customer **PII**:
  - names, emails, phone numbers
  - billing/shipping addresses
  - IP addresses or payment identifiers

## Data minimization
The analytics model stores only the fields required for:
- order-level and item-level revenue analytics
- time-series reporting
- product mix analytics (v1 uses identifiers only)

## Local handling
If you generate exports locally:
- store them outside the repo (e.g., `~/data/` or a separate private folder)
- never commit them to GitHub
- verify `.gitignore` blocks common export formats

## Reporting
All results shown publicly should be aggregated (store/day/product-level) and should not reveal individual customers.
