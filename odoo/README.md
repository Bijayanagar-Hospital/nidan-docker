# Odoo service

The Odoo 19 image is built from **odoo_19_addons**. All build config (Dockerfile, scripts, etc.) lives there:

- **Build context:** `../odoo_19_addons`
- **Dockerfile:** `packages/Dockerfile`

See `odoo_19_addons/packages/BUILD.md` for build and CI details.

This directory is kept for compose wiring only (e.g. odoo-db init); the app image comes from the addons repo.
