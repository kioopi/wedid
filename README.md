# WeDid

**WeDid** is a small open-source app that helps couples build emotional resilience and celebrate their shared life—one positive moment at a time.

It’s a **success & gratitude diary** for two. Every day, both partners can log small or big things that went well: a kind word, a shared laugh, a problem solved, or a moment of connection. Entries are visible to both and meant to be revisited—during good times and tough ones.

### ✨ Why?

Relationships thrive on connection, recognition, and positivity. But in daily life, it’s easy to forget the good.
**WeDid** offers a simple, structured way to build a shared memory of what *works*—a source of strength, joy, and perspective.

Inspired by principles from:
- Positive Psychology (gratitude journaling)
- Gottman Method (emotional bank accounts)
- Narrative Therapy (rewriting relationship stories)
- Emotionally Focused Therapy (building secure bonds)

---

## 🚀 MVP Features

The first version of **WeDid** will focus on simplicity and usability:

### 💬 Daily Entries
- Each partner can add one or more entries per day.
- Entries are short, text-based reflections on what went well.
- Optionally tag entries with a category (e.g. "support", "fun", "teamwork").

### 👀 Shared Journal View
- A timeline view of all entries, grouped by day.
- Each entry is labeled with who wrote it.
- Entries are visible to both partners.

### 🗓️ Calendar Overview
- A simple calendar to navigate by day and see entry density.

---

## 🛠️ Tech Stack

- Backend: Elixir + Phoenix LiveView + Ash Framework
- Frontend: LiveView templates
- Storage: PostgreSQL
- Auth: Magic link or password passcode
- Deployment: Self-hosted Docker

---

## 🎯 Future Ideas (Post-MVP)
- Export to other formats (e.g. JSON, CSV)
- Invite Links to join a couple
- Daily gentle reminder to add an entry (configurable).
- Reactions to partner entries (emoji or short notes)
- Filters or search (e.g. by tag or mood)
- Year-in-review generator
- PDF export for anniversaries
- Offline-first mobile wrapper (PWA or native shell)
- Authentication via other services (Google, Apple, etc.)
- Questions or prompts to guide entries
- Read-access for therapists or coaches
- Voice notes
- Encryption for sensitive data
- Notifications when a partner adds an entry

---

## 🤝 Contributing

This is a small passion project, and contributors are welcome! Whether you're into design, Elixir/Phoenix, UI writing, or psychology-informed UX—jump in.

To get started:
```bash
git clone https://github.com/yourname/wedid.git
cd wedid
mix deps.get
mix phx.server


To start your Phoenix server:

  * Run `mix ash.setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
