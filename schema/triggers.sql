-- Trigger functions to post transactions and update account balances

CREATE OR REPLACE FUNCTION trg_post_transaction() RETURNS trigger AS $$
DECLARE
  from_bal NUMERIC(18,2);
  to_bal NUMERIC(18,2);
  od_limit NUMERIC(18,2);
BEGIN
  -- Only act when transaction becomes 'posted'
  IF NOT (NEW.status = 'posted' AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status <> 'posted'))) THEN
    RETURN NEW;
  END IF;

  -- If from_account exists, debit it
  IF NEW.from_account_id IS NOT NULL THEN
    SELECT balance, COALESCE(overdraft_limit,0) INTO from_bal, od_limit FROM accounts WHERE id = NEW.from_account_id FOR UPDATE;
    IF from_bal - NEW.amount < -od_limit THEN
      RAISE EXCEPTION 'insufficient_funds: account %', NEW.from_account_id;
    END IF;
    UPDATE accounts SET balance = balance - NEW.amount WHERE id = NEW.from_account_id;
    SELECT balance INTO from_bal FROM accounts WHERE id = NEW.from_account_id;
    UPDATE transactions SET from_balance_before = from_bal + NEW.amount, from_balance_after = from_bal WHERE id = NEW.id;
  END IF;

  -- If to_account exists, credit it
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
