# Build Order
 
1. Login with Strava -> backfill activities -> a plain list of runs with distance, pace, data. (Use a manual sync button, no webhooks)
2. Add webhooks and data visualization + inngest
3. User can input plan and app recognizes where they are in the plan
4. LLM chat with database tools

## Phase 1 — Data Pipeline
 
**Goal:** My Strava runs live in my own Postgres database and stay in sync. Bare bones UI displaying 
 
## 1. Environment & secrets
- [x] Add .env.local file + .gitignore
- [x] Add Strava env variables

## 2. Database Setup
- [x] Add Neon connection string to env
- [x] Add Neon dependencies
- [x] Add Drizzle dependencies
- [x] Create schema tables for users + user data
- [x] Run schema generation + migration

## 3. Authentication
- [ ] Install Auth.js + Drizzle adapter
- [ ] Configure Strava OAuth provider
- [ ] Reconcile Auth.js's users table with existing users_table
- [ ] Confirm login flow works end-to-end
- [ ] Generate + run migration for Auth.js's adapter tables

## 4. Strava Sync
- [ ] Build shared Strava API client (handles token refresh)
- [ ] Historical backfill: fetch + insert past activities
- [ ] Manual "sync" button/route to trigger backfill
- [ ] Plain list view of synced runs