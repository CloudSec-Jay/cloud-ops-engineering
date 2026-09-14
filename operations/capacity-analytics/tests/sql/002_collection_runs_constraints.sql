START TRANSACTION;

-- Test 1: invalid data origin
INSERT INTO collection_runs (
    data_origin, aws_region, project_tag,
    started_at, finished_at, status, discovered_count
)
VALUES (
    'test', 'us-east-1', 'sql-constraint-test',
    UTC_TIMESTAMP(6), NULL, 'success', 2
);

-- Test 2: invalid status
INSERT INTO collection_runs (
    data_origin, aws_region, project_tag,
    started_at, finished_at, status, discovered_count
)
VALUES (
    'synthetic', 'us-east-1', 'sql-constraint-test',
    UTC_TIMESTAMP(6), NULL, 'ongoing', 2
);

-- Test 3: finish before start
INSERT INTO collection_runs (
    data_origin, aws_region, project_tag,
    started_at, finished_at, status, discovered_count
)
VALUES (
    'synthetic', 'us-east-1', 'sql-constraint-test',
    '2026-09-13 12:00:00.000000',
    '2026-09-13 11:00:00.000000',
    'failure',
    2
);

SELECT COUNT(*) AS invalid_rows_inserted
FROM collection_runs
WHERE project_tag = 'sql-constraint-test';

ROLLBACK;