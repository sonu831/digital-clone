-- ═══════════════════════════════════════════════════════════════════════════════
--  DIGITAL CLONE — Database bootstrap
--  Runs ONCE, automatically, on the first start of an empty Postgres volume
--  (via /docker-entrypoint-initdb.d). To re-run, wipe the postgres_data volume.
--
--  Design note: this schema is SPOKE-AGNOSTIC. Slack, Discord, a broker poller,
--  or any future integration all write to the SAME `clone.activity_logs` table
--  using the standardized columns below. This is the persistence side of the
--  Hub-and-Spoke contract (see docs/04-workflow-design.md).
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pgcrypto;        -- gen_random_uuid()

-- Keep app objects out of `public` for cleanliness and least-privilege grants.
CREATE SCHEMA IF NOT EXISTS clone;

-- ── Core event log ────────────────────────────────────────────────────────────
-- Every meaningful event in the system lands here exactly once.
CREATE TABLE IF NOT EXISTS clone.activity_logs (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    -- WHICH spoke produced this (e.g. 'slack', 'discord', 'cron', 'broker').
    source          TEXT         NOT NULL,
    -- WHAT happened (e.g. 'inbound_message', 'task_created', 'debrief', 'error').
    event_type      TEXT         NOT NULL,

    -- Ties an inbound event -> its AI output -> its resulting action(s).
    correlation_id  UUID         NOT NULL DEFAULT gen_random_uuid(),

    actor           TEXT,                         -- user id / username that triggered it
    channel         TEXT,                         -- channel / thread identifier

    user_query      TEXT,                         -- human-readable input
    ai_summary      TEXT,                         -- human-readable AI result

    -- Standardized JSON contracts (validated against contracts/*.schema.json):
    inbound_event   JSONB,                        -- the normalized inbound payload
    ai_output       JSONB,                        -- the normalized AI decision/output

    status          TEXT         NOT NULL DEFAULT 'logged'  -- logged | actioned | error
);

COMMENT ON TABLE  clone.activity_logs IS 'Append-only, spoke-agnostic event log for the Digital Clone.';
COMMENT ON COLUMN clone.activity_logs.correlation_id IS 'Shared id linking an inbound event to its AI output and downstream actions.';

-- ── Indexes for the common access patterns ────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_activity_created_at   ON clone.activity_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_source       ON clone.activity_logs (source);
CREATE INDEX IF NOT EXISTS idx_activity_event_type   ON clone.activity_logs (event_type);
CREATE INDEX IF NOT EXISTS idx_activity_correlation  ON clone.activity_logs (correlation_id);
-- Fast querying inside the JSON payloads (e.g. WHERE ai_output @> '{"path":"beta"}').
CREATE INDEX IF NOT EXISTS idx_activity_inbound_gin  ON clone.activity_logs USING GIN (inbound_event);
CREATE INDEX IF NOT EXISTS idx_activity_aiout_gin    ON clone.activity_logs USING GIN (ai_output);

-- ── Convenience view: "today's activity" feeding the cron debrief ─────────────
CREATE OR REPLACE VIEW clone.v_today AS
    SELECT id, created_at, source, event_type, actor, channel, user_query, ai_summary, status
    FROM clone.activity_logs
    WHERE created_at::date = (now() AT TIME ZONE 'UTC')::date
    ORDER BY created_at ASC;

COMMENT ON VIEW clone.v_today IS 'All events recorded today (UTC) — input to the evening debrief workflow.';
