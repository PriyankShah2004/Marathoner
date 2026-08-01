# Architecture — Marathon Training App
 
Next.js application which displays data from Strava, visualizes it, connects to a training plan, and offers LLM chat assistant which is connected to the users data and can conversate based on it.

---

## System Overview
 
```
┌─────────────┐     OAuth + API      ┌──────────────┐
│   Strava    │◄────────────────────►│              │
│             │─── webhooks ────────►│   Next.js    │
└─────────────┘                      │  (App Router)│
                                     │              │
┌─────────────┐   tool calls / SQL   │  API routes  │
│  Anthropic  │◄────────────────────►│  Server      │
│  API (LLM)  │                      │  Components  │
└─────────────┘                      └──────┬───────┘
                                            │ Drizzle ORM
┌─────────────┐   background jobs    ┌──────▼───────┐
│  Inngest    │◄────────────────────►│  PostgreSQL  │
└─────────────┘                      └──────────────┘
```
 
Everything runs inside one Next.js application. There is no separate backend service — API routes, server components, and background job handlers cover all server-side needs.
 
---
 
## Core Framework
 
**Next.js 15 (App Router) + TypeScript**, deployed on Vercel.

---
 
## Database
 
**PostgreSQL**, hosted on Neon through **Drizzle ORM**.
 
Drizzle is chosen over Prisma because the application is analytics-heavy: weekly mileage, pace trends, and plan-versus-actual comparisons are fundamentally SQL problems. Drizzle stays close to SQL while retaining full type safety, and its raw SQL escape hatch is valuable for aggregation queries.
 
Key schema decisions:
 
- **Raw payload preservation.** Each Strava activity row stores the full API response in a `jsonb` column alongside normalized columns (distance, moving time, average pace, heart rate) for frequently queried fields. If Strava adds fields or a new statistic is needed later, the data already exists locally — no re-fetching against rate limits.
- **Streams stored separately.** Per-second data (GPS, heart rate, pace streams) is large. It lives in a dedicated table and is fetched from Strava only for activities opened in detail view.
- **Plans and matches are separate concerns.** The training plan (weeks → workouts with type, target distance/pace/duration) occupies one set of tables. The mapping of completed activities to planned workouts occupies another. Matching a real run to a planned workout is inherently fuzzy — an easy 5-miler could be Tuesday's recovery run or a swapped Wednesday tempo — so matches are generated as suggestions that the athlete confirms or overrides.
Drizzle migrations are generated with drizzle-kit and **committed to the repository** — they are source code.
 
---
 
## Authentication
 
**Auth.js (NextAuth v5)** with the built-in **Strava OAuth provider**.
 
This collapses two problems into one: logging in *is* connecting Strava. No separate account-linking flow exists.
 
The critical implementation detail is token lifecycle. Strava access tokens expire every six hours. Refresh tokens are stored server-side, and every Strava API call passes through a single shared client helper that checks expiry and rotates tokens before making the request. Refresh logic exists in exactly one place.
 
Secrets (`STRAVA_CLIENT_ID`, `STRAVA_CLIENT_SECRET`, `AUTH_SECRET`, `DATABASE_URL`) live in `.env.local`, which is gitignored. No secret is ever prefixed with `NEXT_PUBLIC_`, which would expose it to the browser bundle.
 
---
 
## Strava Integration
 
Two data paths:
 
1. **Historical backfill.** On first login, a background job pages through the athlete's activity history and stores it. This is the only heavy polling the system ever performs.
2. **Webhooks.** Strava pushes an event to the application's webhook endpoint whenever an activity is created, updated, or deleted. The handler validates the payload and enqueues a job to fetch the full activity. No polling loops.
This design is driven by Strava's rate limits (approximately 200 requests per 15 minutes, 2,000 per day). Webhooks keep data fresh while consuming minimal quota.
 
---
 
## Background Jobs
 
**Inngest** (Trigger.dev is an equivalent alternative), integrated directly into the Next.js application.
 
Jobs handle anything that should not block a request: processing webhook events, running the initial backfill, and nightly aggregation of derived statistics (weekly volume, training load, plan adherence scores). Inngest provides retries, queuing, and durable execution without dedicated infrastructure, and operates within Vercel's serverless model.
 
---
 
## Visualization
 
- **Recharts** for standard charts — weekly volume bars, pace trends, adherence over time. shadcn/ui's chart components wrap it cleanly.
- **MapLibre GL** (free, no token required) for route maps, rendering decoded Strava polylines. Mapbox GL is a drop-in upgrade if richer basemaps are needed later.
- **visx / D3** reserved for future custom visuals such as calendar heatmaps or plan-overlay charts.
---
 
## Training Plan Engine
 
The plan is structured data, not free text: a plan contains weeks, weeks contain workouts, and each workout carries a type (easy, tempo, interval, long run, rest) and targets (distance, pace, and/or duration).
 
Adherence tracking is deliberately a **query problem, not a code problem**. Once activities are matched to planned workouts, adherence becomes SQL over the matches table: completion rate, volume delta, pace versus target. This is a second reason for Drizzle's SQL-forward design.
 
---
 
## LLM Assistant
 
**Anthropic API (Claude)**.
 
The AI SDK handles streaming chat UI in Next.js and is provider-agnostic should the model choice change.
 
The important architectural pattern: the LLM is given **tools that query the database** — `get_recent_mileage`, `get_plan_adherence`, `get_workout_detail` — rather than having raw statistics injected into the prompt. The model pulls exactly the data each question requires. This approach is cheaper, more accurate, and scales as months of training data accumulate. The chat layer is built last, since it becomes substantially more useful once real data and adherence queries exist for it to call.
 
---
 
## Validation & UI
 
- **Zod** validates everything crossing a boundary: Strava webhook payloads, API responses, and plan input forms. It pairs with the database layer via `drizzle-zod`.
- **Tailwind CSS + shadcn/ui** for the interface — fast to build with, easy to customize, and free of component-library lock-in since shadcn code is copied into the repository.
---

 
 