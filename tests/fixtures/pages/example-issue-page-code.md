# SHOP-12: Resumable photo uploads, code

Code for [SHOP-12: Resumable photo uploads](example-issue-page.md) · Standard: 2

## Every changed file

### Browser

| File | What it does in this change |
| ---- | --------------------------- |
| `web/src/upload/pieces.ts` | Cuts a photo into numbered pieces. |
| `web/src/upload/resume.ts` | Asks which pieces the service holds and sends the rest. |

### Upload service

| File | What it does in this change |
| ---- | --------------------------- |
| `api/src/upload/store.ts` | Keeps pieces by upload id and reports which it holds. |
| `api/src/upload/join.ts` | Joins the pieces and hands the photo to the product page. |

## Code walkthrough

### 1. The browser cuts the photo into numbered pieces

The photo is read in 1 MB slices and each slice gets its position as a number.

### 2. It asks the service which pieces it already holds

One request returns the numbers the service has, so nothing is sent twice.

### 3. It sends only the missing pieces

The loop skips every number the service already listed.

### 4. The service stores each piece under the upload id

A piece is written once under its id and number, so a repeat is harmless.

### 5. The last piece triggers the join

When every number is present the service joins them and publishes the photo.
