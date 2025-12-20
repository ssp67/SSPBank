-- Posting trigger: updates balances when transactions are posted

CREATE OR REPLACE FUNCTION trg_post_transaction() RETURNS trigger AS $$
DECLARE
  from_bal NUMERIC(18,2);
  to_bal NUMERIC(18,2);
  od_limit NUMERIC(18,2);
BEGIN
  IF NOT (NEW.status = 'posted' AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status <> 'posted'))) THEN
    RETURN NEW;
  END IF;

  IF NEW.from_account_id IS NOT NULL THEN
    SELECT balance, COALESCE(overdraft_limit,0) INTO from_bal, od_limit FROM accounts WHERE id = NEW.from_account_id FOR UPDATE;
    IF from_bal - NEW.amount < -od_limit THEN
      RAISE EXCEPTION 'insufficient_funds: account %', NEW.from_account_id;
    END IF;
    UPDATE accounts SET balance = balance - NEW.amount WHERE id = NEW.from_account_id;
    SELECT balance INTO from_bal FROM accounts WHERE id = NEW.from_account_id;
    UPDATE transactions SET from_balance_before = from_bal + NEW.amount, from_balance_after = from_bal WHERE id = NEW.id;
  END IF;

  IF NEW.to_account_id IS NOT NULL THEN
    SELECT balance INTO to_bal FROM accounts WHERE id = NEW.to_account_id FOR UPDATE;
    UPDATE accounts SET balance = balance + NEW.amount WHERE id = NEW.to_account_id;
    SELECT balance INTO to_bal FROM accounts WHERE id = NEW.to_account_id;
    UPDATE transactions SET to_balance_before = to_bal - NEW.amount, to_balance_after = to_bal WHERE id = NEW.id;
  END IF;

  UPDATE transactions SET posted_at = now() WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_transaction AFTER INSERT OR UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION trg_post_transaction();

-- AUDIT: generic trigger to log inserts/updates/deletes
CREATE OR REPLACE FUNCTION audit_log_trigger() RETURNS trigger AS $$
DECLARE
  who TEXT := current_user;
  payload JSONB;
BEGIN
  IF TG_OP = 'DELETE' THEN
    payload := row_to_json(OLD)::jsonb;
  ELSE
    payload := row_to_json(NEW)::jsonb;
  END IF;

  INSERT INTO audit_logs (who, action, table_name, row_id, details) VALUES (
    who,
    TG_OP,
    TG_TABLE_NAME,
    COALESCE( (CASE WHEN TG_OP = 'DELETE' THEN OLD.id::text ELSE NEW.id::text END), '' ),
    payload
  );
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attach audit triggers to core tables
DO $$
BEGIN
  EXECUTE 'CREATE TRIGGER audit_customers AFTER INSERT OR UPDATE OR DELETE ON personal_customers FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();';
  EXECUTE 'CREATE TRIGGER audit_accounts AFTER INSERT OR UPDATE OR DELETE ON accounts FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();';
  EXECUTE 'CREATE TRIGGER audit_transactions AFTER INSERT OR UPDATE OR DELETE ON transactions FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();';
  EXECUTE 'CREATE TRIGGER audit_cards AFTER INSERT OR UPDATE OR DELETE ON cards FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();';
  EXECUTE 'CREATE TRIGGER audit_loans AFTER INSERT OR UPDATE OR DELETE ON loans FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();';
END;
$$ LANGUAGE plpgsql;
