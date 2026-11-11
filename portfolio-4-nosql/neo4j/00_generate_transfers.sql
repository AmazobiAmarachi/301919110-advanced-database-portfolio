-- Creates realistic transfer activity in PostgreSQL (via transfer_funds) to export to Neo4j,
-- including a planted money-laundering ring 500 -> 600 -> 700 -> 800 -> 500
SELECT setseed(0.7);
DO $$ DECLARE f INT; t INT; BEGIN
  FOR i IN 1..400 LOOP
    f := 200 + floor(random()*1800)::int; t := 200 + floor(random()*1800)::int;
    IF f <> t AND f NOT IN (500,600,700,800) AND t NOT IN (500,600,700,800) THEN
      BEGIN CALL transfer_funds(f, t, round((500 + random()*20000)::numeric,2));
      EXCEPTION WHEN others THEN NULL; END;   -- skip insufficient-funds cases
    END IF;
  END LOOP;
END $$;
UPDATE accounts SET balance = balance + 300000 WHERE account_id = 500;  -- seed the ring
CALL transfer_funds(500, 600, 250000);
CALL transfer_funds(600, 700, 245000);
CALL transfer_funds(700, 800, 240000);
CALL transfer_funds(800, 500, 235000);
