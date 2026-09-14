START TRANSACTION;

INSERT INTO collection_runs (
	data_origin,
	aws_region,
	project_tag,
	started_at,
	finished_at,
	status,
	discovered_count
)

VALUES (
	'synthetic',
	'us-east-1',
	'sql-smoke-test',
	UTC_TIMESTAMP(6),
	NULL,
	'success',
	2
);

SET @test_run_id = LAST_INSERT_ID();

SELECT *
FROM collection_runs
WHERE collection_run_id = @test_run_id;

ROLLBACK;

SELECT COUNT(*) AS rows_remaining_after_rollback
FROM collection_runs
WHERE collection_run_id = @test_run_id;