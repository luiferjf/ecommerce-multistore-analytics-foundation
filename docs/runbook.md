# Runbook — Foundation v1

Operational guide to refresh the model, validate it, and publish safely (no PII).

---

## 1) Refresh workflow (manual batch)

### A) Extract (per store DB)
- Use DBeaver on each source DB (read-only).
- Export two CSVs per store:
  - `orders_<STORE>.csv`
  - `order_items_<STORE>.csv`

### B) Load staging (analytics DB)
In `u298795178_foundation_v1`:
- Import CSVs into:
  - `stg_orders`
  - `stg_order_items`

### C) Rebuild the model (schema + views)
Run in this order:
1. `sql/ddl.sql`
2. (Run your rebuild/populate scripts for dims/facts as per your process)
3. `sql/views.sql`

### D) Validate
Run:
- `sql/tests.sql`

Expected: tests return `0` or `OK`.

---

## 2) Publish checklist (portfolio-safe)
Before posting screenshots or sharing outputs:
- [ ] No raw rows with customer identifiers
- [ ] No email/name/address/phone fields visible
- [ ] Only aggregated outputs (store/day/product mix)
- [ ] Store codes are OK to show (RBN/PA/VIC/NEB)
- [ ] Hide account details / personal tabs from screenshots

---

## 3) Git essentials (minimum)
```bash
git status
git add .
git commit -m "Describe change"
git push

---

## 4) Repo source of truth

- Executable SQL: /sql
- Documentation: /docs
- No data exports committed (blocked by .gitignore)

---
