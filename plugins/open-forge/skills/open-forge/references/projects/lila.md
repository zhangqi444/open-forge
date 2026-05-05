---
name: Lila (Lichess)
description: "Open-source chess server powering lichess.org — real-time games, tournaments, puzzles, analysis, and a full chess community platform. Scala. AGPL-3.0."
---

# Lila (Lichess)

Lila (li[chess in sca]la) is the open-source chess server that powers lichess.org — the world's second-largest chess platform, entirely free and ad-free. It provides real-time gameplay, tournaments, simuls, puzzles, analysis boards, forums, teams, studies, and a full-featured chess API.

Maintained by lichess.org's volunteer team. The live site serves millions of games per day; the codebase is among the most starred self-hostable applications on GitHub (18k+ stars).

**Important:** Self-hosting a full Lila instance is **extremely complex**. It has many dependencies (Scala, MongoDB, Elasticsearch, Redis, Stockfish AI cluster, lila-ws WebSocket server, etc.) and is designed to run at internet scale. It is not a "spin up with docker compose" application. The setup guide is aimed at developers contributing to Lichess, not end-users wanting a simple chess server.

Use cases: (a) contributing to Lichess development (b) running a private chess club server (c) building a specialized chess community platform (d) research using the Lichess API and open game database.

Features (full lichess.org):

- **Real-time chess** — standard, chess960, variants (crazyhouse, antichess, etc.)
- **Tournaments** — Swiss, Arena, Team Battles
- **Puzzle trainer** — 500k+ puzzles; spaced repetition
- **Computer analysis** — Stockfish integration; per-game analysis
- **Studies** — shared annotated analysis boards
- **Forums and teams** — community features
- **Mobile apps** — official iOS and Android apps
- **Open API** — REST API for games, users, tournaments, analysis
- **PGN database** — all rated games freely downloadable

- Upstream repo: https://github.com/lichess-org/lila
- Homepage: https://lichess.org/
- API docs: https://lichess.org/api
- Dev setup: https://github.com/lichess-org/lila/wiki/Lichess-Development-Onboarding

## Architecture

Lila is a large, complex distributed system:

- **Scala 3 / Play 2.8** — main app server
- **MongoDB** — primary database; stores 12+ billion games
- **Elasticsearch** — game search indexing
- **Redis** — WebSocket coordination, caching, queues
- **lila-ws** — separate WebSocket server (Scala/Akka)
- **Stockfish** — AI analysis; runs as a separate cluster (fishnet)
- **nginx** — reverse proxy
- **TypeScript + Sass** — frontend

This is a multi-repository project:
- `lila` — main server
- `lila-ws` — WebSocket server
- `fishnet` — distributed Stockfish AI
- `scalachess` — pure chess logic library
- `lila-db-dump` — database tools

## Self-hosting reality check

Running Lila in production (even privately) requires:

- Scala build toolchain (sbt)
- MongoDB 5+
- Elasticsearch 8+
- Redis 6+
- Stockfish compiled for your platform
- `lila-ws` running separately
- nginx reverse proxy
- Significant RAM (16+ GB for reasonable performance)
- Multiple services coordinated

**There is no official Docker Compose file for production.** The development setup uses scripts but is still involved.

If you want a simple self-hosted chess server, consider **chesslablab/board-server** or other lighter alternatives. Lila is the right choice only if you specifically need Lichess's feature set and have developer resources.

## Development setup

```sh
git clone --recursive https://github.com/lichess-org/lila.git
cd lila

# Requires: sbt, MongoDB, Redis, Elasticsearch, Node.js
# Full instructions:
# https://github.com/lichess-org/lila/wiki/Lichess-Development-Onboarding

./lila.sh  # sbt wrapper
# Inside sbt:
run
```

See the [development onboarding wiki](https://github.com/lichess-org/lila/wiki/Lichess-Development-Onboarding) for the complete setup procedure including all dependencies.

## Lichess API (use without self-hosting)

If you want to build chess applications, the **Lichess API** is freely available and doesn't require self-hosting:

```
# Get user info
GET https://lichess.org/api/user/{username}

# Get user's games
GET https://lichess.org/api/games/user/{username}

# Stream real-time game events (requires OAuth)
GET https://lichess.org/api/stream/game/{gameId}

# Download open game database
https://database.lichess.org/
```

Full API docs: https://lichess.org/api

## Gotchas

- **Self-hosting complexity** — this is not a weekend project. The development setup guide runs to dozens of steps. Factor in significant time and expertise.
- **No official production Docker image** — community Docker attempts exist but are not maintained by the Lichess team. Expect maintenance burden.
- **MongoDB at scale** — Lichess uses MongoDB for billions of games. For a small private server (thousands of games), this is fine; it's just a heavier dependency than a simple SQL database.
- **Stockfish cluster (fishnet)** — the distributed AI analysis system is designed for Lichess's scale. For a private server, you can run a single local Stockfish instance but integration requires configuration.
- **License** — AGPL-3.0. If you modify Lila and run it as a network service, you must release your modifications under AGPL-3.0.
- **Lichess asks respectfully** — the Lichess team has a note in the repository: they're happy for self-hosting but ask that you don't impersonate lichess.org or mislead users.
- **Game database** — the full Lichess open database (billions of games) is freely available at database.lichess.org for research use without self-hosting the server.
- **Alternatives for simpler chess servers:** chesslablab (simpler stack), Fritz (commercial), ChessDB (game database tool), or using the Lichess API directly.

## Links

- Repo: https://github.com/lichess-org/lila
- Website: https://lichess.org/
- Development onboarding: https://github.com/lichess-org/lila/wiki/Lichess-Development-Onboarding
- API documentation: https://lichess.org/api
- Open game database: https://database.lichess.org/
- Lichess source repositories: https://lichess.org/source
- WebSocket server (lila-ws): https://github.com/lichess-org/lila-ws
- Distributed Stockfish (fishnet): https://github.com/lichess-org/fishnet
- Discord: https://discord.gg/lichess
