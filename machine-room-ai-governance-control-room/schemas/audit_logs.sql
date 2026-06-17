-- =============================================================================
-- Machine-Room.AI Governance Control Room
-- Schema: audit_logs
-- Purpose: Append-only record of every consequential action in the system.
--          This is the LOG stage of VERIFY -> CONTROL -> LOG -> DEGRADE SAFE.
--
-- Design rules:
--   1. Append-only. No UPDATE, no DELETE. Corrections are new rows.
--   2. Every row is self-sufficient: who / what / to what / from -> to / when / why.
--   3. No secrets, credentials, or unnecessary sensitive payloads.
--
-- Dialect: PostgreSQL (portable to most SQL engines with minor edits).
-- Note: gen_random_uuid() is built-in on PostgreSQL 13+. On older versions,
--       enable pgcrypto first:  CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- =============================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
    -- Unique entry identifier.
    id              uuid         PRIMARY KEY DEFAULT gen_random_uuid(),

    -- WHO acted. Authenticated identity, not a claimed one.
    actor_id        uuid         NOT NULL,
    actor_role     text         NOT NULL,

    -- WHAT was acted upon.
    target_type     text         NOT NULL,   -- e.g. 'entity', 'listing', 'reveal_request'
    target_id       uuid         NOT NULL,

    -- WHAT was done.
    action          text         NOT NULL,   -- e.g. 'verify', 'reject', 'approve', 'suspend', 'reveal'

    -- WHY it was done. Justification or context.
    reason          text,

    -- STATE change. Either side may be null for create / terminal events.
    previous_state  text,
    new_state       text,

    -- Correlation and idempotency key. Ties retries and traces together.
    request_id      text         NOT NULL,

    -- Structured extras that are not part of the reconstruction minimum.
    -- Keep this free of secrets and of duplicated sensitive payloads.
    metadata        jsonb        NOT NULL DEFAULT '{}'::jsonb,

    -- WHEN it happened.
    created_at      timestamptz  NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------
-- Reconstruct the history of a single target.
CREATE INDEX IF NOT EXISTS idx_audit_logs_target
    ON audit_logs (target_type, target_id, created_at DESC);

-- Review everything a single actor did.
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor
    ON audit_logs (actor_id, created_at DESC);

-- Trace or de-duplicate by request.
CREATE INDEX IF NOT EXISTS idx_audit_logs_request
    ON audit_logs (request_id);

-- Time-window queries for incident review.
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at
    ON audit_logs (created_at DESC);

-- -----------------------------------------------------------------------------
-- Immutability
-- -----------------------------------------------------------------------------
-- Append-only is enforced at the storage layer, not by convention.
--
-- 1) Privilege model: grant INSERT and SELECT only. Never grant UPDATE/DELETE
--    to application roles. Replace `app_role` with your application role name.
--
--   REVOKE UPDATE, DELETE ON audit_logs FROM app_role;
--   GRANT  INSERT, SELECT ON audit_logs TO   app_role;
--
-- 2) Defense in depth: reject UPDATE/DELETE outright with a trigger, so even a
--    mis-granted privilege cannot mutate history.

CREATE OR REPLACE FUNCTION audit_logs_block_mutation()
RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit_logs is append-only: % is not permitted', TG_OP;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_logs_no_update ON audit_logs;
CREATE TRIGGER trg_audit_logs_no_update
    BEFORE UPDATE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION audit_logs_block_mutation();

DROP TRIGGER IF EXISTS trg_audit_logs_no_delete ON audit_logs;
CREATE TRIGGER trg_audit_logs_no_delete
    BEFORE DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION audit_logs_block_mutation();

-- -----------------------------------------------------------------------------
-- Optional: row-level security scaffold (enable if your platform uses RLS)
-- -----------------------------------------------------------------------------
-- ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
--
-- -- Privileged readers may read all entries.
-- CREATE POLICY audit_logs_read_admin ON audit_logs
--     FOR SELECT USING ( /* your admin-role predicate here */ true );
--
-- -- Inserts are allowed for authenticated application contexts.
-- CREATE POLICY audit_logs_insert ON audit_logs
--     FOR INSERT WITH CHECK ( /* your authenticated predicate here */ true );
--
-- -- No UPDATE or DELETE policies are defined, by design.

-- -----------------------------------------------------------------------------
-- Column documentation
-- -----------------------------------------------------------------------------
COMMENT ON TABLE  audit_logs                IS 'Append-only record of consequential actions. Never updated or deleted.';
COMMENT ON COLUMN audit_logs.actor_id       IS 'Authenticated identity that performed the action.';
COMMENT ON COLUMN audit_logs.actor_role     IS 'Role under which the actor was operating at action time.';
COMMENT ON COLUMN audit_logs.target_type    IS 'Kind of entity acted upon (entity, listing, reveal_request, etc.).';
COMMENT ON COLUMN audit_logs.target_id      IS 'Identifier of the specific entity acted upon.';
COMMENT ON COLUMN audit_logs.action         IS 'Action performed (verify, reject, approve, suspend, reveal, etc.).';
COMMENT ON COLUMN audit_logs.reason         IS 'Justification or context for the action.';
COMMENT ON COLUMN audit_logs.previous_state IS 'State before the action; null for creation events.';
COMMENT ON COLUMN audit_logs.new_state      IS 'State after the action; null for non-state-changing events.';
COMMENT ON COLUMN audit_logs.request_id     IS 'Correlation and idempotency key tying retries and traces together.';
COMMENT ON COLUMN audit_logs.metadata       IS 'Structured extras. Must not contain secrets or duplicated sensitive payloads.';
COMMENT ON COLUMN audit_logs.created_at     IS 'Timestamp the action occurred.';
