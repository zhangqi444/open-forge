# Nextcloud Tasks

**CalDAV-based task management app for Nextcloud — manage todos with subtasks, priorities, due dates, and smart collections. Syncs with Apple Reminders, Android (DAVx5/OpenTasks), Thunderbird, and more.**
GitHub: https://github.com/nextcloud/tasks

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Nextcloud App Store | Requires existing Nextcloud instance |

---

## Inputs to Collect

### Required
- Existing Nextcloud installation

---

## Software-Layer Concerns

### Installation
1. In Nextcloud, go to **Apps** → **Organization** → find **Tasks** → click **Enable**
2. Open Tasks from the Nextcloud app menu

No separate container or service required.

### Sync-compatible apps (CalDAV)
| App | Platform |
|-----|----------|
| Apple Reminders | iOS, macOS |
| DAVx5 | Android |
| OpenTasks | Android |
| 2Do | Android, iOS, macOS |
| Thunderbird Lightning | Cross-platform |
| BusyCal | macOS |
| Tasks.org | Android |
| Outlook CalDAV Synchronizer | Windows |
| GNOME Todo (via GNOME Online Accounts) | Linux |
| Kalendar | Linux (KDE) |
| planify | Linux |
| jtx Board | Android |
| vdirsyncer | Linux, BSD |
| QOwnNotes | Cross-platform (read-only) |

### Key features
- Create, edit, delete tasks with title, description, start/due dates, priority, status
- Subtasks support
- Drag-and-drop between calendars or as subtasks
- Smart collections: important, current, upcoming

---

## Upgrade Procedure

Nextcloud will notify you of available updates. Upgrade from the Apps management page or via `occ app:update tasks`.

---

## Gotchas

- Requires an existing Nextcloud instance — this is a Nextcloud app, not a standalone service
- Some anti-tracking browser extensions (e.g. ClearURLs) strip ETags and cause false conflict reports — add an exception for your Nextcloud domain
- Server-side ETag modification (e.g. some proxy configs) can also cause conflict issues

---

## References
- GitHub: https://github.com/nextcloud/tasks#readme
