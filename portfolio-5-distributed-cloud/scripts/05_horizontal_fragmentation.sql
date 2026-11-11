-- Portfolio 5 - Horizontal fragmentation of CUSTOMERS by region (list partitioning).
-- Each fragment could live on a different node/shard; here they are partitions of one server.
DROP TABLE IF EXISTS customers_frag CASCADE;
CREATE TABLE customers_frag (LIKE customers INCLUDING DEFAULTS) PARTITION BY LIST (region_id);
CREATE TABLE customers_lagos     PARTITION OF customers_frag FOR VALUES IN (1);          -- Lagos
CREATE TABLE customers_north     PARTITION OF customers_frag FOR VALUES IN (2, 4, 7);    -- Abuja, Kano, Kaduna
CREATE TABLE customers_south     PARTITION OF customers_frag FOR VALUES IN (3, 5, 6, 8); -- Rivers, Enugu, Oyo, Anambra
INSERT INTO customers_frag SELECT * FROM customers;
ANALYZE customers_frag;
-- Completeness check: the union of fragments equals the original relation
SELECT tableoid::regclass AS fragment, count(*) FROM customers_frag GROUP BY 1 ORDER BY 1;
SELECT (SELECT count(*) FROM customers) AS original_rows, (SELECT count(*) FROM customers_frag) AS rows_in_all_fragments;
-- Partition pruning: a Lagos query touches ONLY the Lagos fragment (fragmentation transparency)
EXPLAIN (COSTS OFF) SELECT count(*) FROM customers_frag WHERE region_id = 1;
EXPLAIN (COSTS OFF) SELECT count(*) FROM customers_frag WHERE region_id IN (4, 7);
