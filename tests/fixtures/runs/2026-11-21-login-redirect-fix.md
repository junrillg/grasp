# 2026-11-21: Login redirect fix

Status: partial · Codex · branch `fix/login-redirect`

**Asked:** Users land on a blank page after login.
**Changed:** Login returns users to the page they came from; the mobile app isn't fixed yet.
**Checked:** not checked
**Problems:** The test database isn't reachable, so nothing ran | the mobile app still lands on a blank page.
**Next:** Run the tests where the database is reachable, then fix the mobile app.

> [!WARNING]
> The mobile app builds its own return address, so this fix doesn't reach it.

```text
- **Changed:** a line inside a code fence is not the record's own line
```
