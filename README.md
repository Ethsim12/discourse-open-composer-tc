# discourse-open-composer-tc

A Discourse **theme component** that automatically opens the post composer
(new topic or reply) based on a one-shot frontend signal or page location.

This is useful for:
- onboarding / welcome flows
- invite acceptance
- account activation redirects
- “introduce yourself” categories
- guided first actions for new users

The component is frontend-only, upgrade-safe, and does **not** override core
templates.

---

## How it works (high level)

1. A redirect or script sets a **one-shot signal** in `localStorage`
2. On the next page load, the theme component:
   - reads the signal
   - opens the composer via Discourse’s composer service
   - clears the signal so it only runs once
3. Optionally, the composer can also auto-open on specific paths using defaults

---

## Installation

1. Go to **Admin → Customize → Themes**
2. Install → **From a Git repository**
3. Paste:
```
https://github.com/Ethsim12/discourse-open-composer-tc
```
4. Enable the component on the desired theme
5. Configure settings under the component

---

## LocalStorage signal (primary trigger)

The component looks for a JSON payload stored under a configurable
`localStorage` key.

### Example payload
```
localStorage.setItem(
“open_composer_once”,
JSON.stringify({
mode: “new_topic”,
categoryId: 19,
title: “Welcome!”,
body: “Introduce yourself 🙂”
})
);
```
Then redirect the user:
```
window.location.href = “/c/introductions”;
```
On the next page load:
- the composer opens
- the payload is consumed
- the key is removed automatically

This makes the behaviour **one-shot**.

---

## Settings reference

### Core

#### `open_composer_enabled`
Master on/off switch.

- `true` → component active
- `false` → component does nothing

---

#### `open_composer_storage_key`
The `localStorage` key name to read the payload from.

Default:
```
open_composer_once
```
Change this if:
- you want multiple independent triggers
- you need to avoid collisions with other code

---

## Path-based fallback (optional)

These settings are only used if **no localStorage payload exists**.

---

#### `open_composer_use_defaults_on_paths`
If enabled, the composer will auto-open on certain pages using default values.

- `false` → only localStorage triggers work
- `true` → path-based fallback enabled

---

#### `open_composer_paths`
A list of **URL path prefixes** that trigger the fallback.

Examples:
`/welcome`
`/c/introductions`
Rules:
- no domain
- no query string
- simple `startsWith` match

---

## Composer defaults (used by fallback)

---

#### `open_composer_default_mode`
Which composer to open.

Options:
- `new_topic`
- `reply`

---

#### `open_composer_default_category_id`
Category ID for **new topic** composer.

Ignored for replies.

---

#### `open_composer_default_topic_id`
Topic ID to reply to when mode is `reply`.

- required for replies
- ignored for new topics
- invalid IDs safely fall back to new topic

---

#### `open_composer_default_title`
Pre-filled topic title (new topics only).

---

#### `open_composer_default_body`
Pre-filled body text.

Used for:
- new topics
- replies

---

## Common use cases

### Welcome / Introductions flow

- Redirect new users to `/c/introductions`
- Set a localStorage payload with title + body
- Composer opens immediately

---

### Invite acceptance

- After invite accept, set payload
- Redirect to a specific category or topic
- Open composer once, then clear

---

### Always-open composer page

- Enable `open_composer_use_defaults_on_paths`
- Add `/welcome` to paths
- Visiting `/welcome` always opens a composer

(No redirects required.)

---

## Why this approach

- ✅ Uses supported theme component APIs
- ✅ No core template overrides
- ✅ No server-side changes
- ✅ Upgrade-safe
- ✅ Works for both new-topic and reply composers

This follows the same frontend model Discourse itself uses to open the composer.

---

## License

MIT
