CREATE TABLE collection_runs (
    collection_run_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    data_origin VARCHAR(16) NOT NULL,
    aws_region VARCHAR(32) NOT NULL,
    project_tag VARCHAR(128) NOT NULL,
    started_at DATETIME(6) NOT NULL,
    finished_at DATETIME(6) NULL,
    status VARCHAR(16) NOT NULL,
    discovered_count INT UNSIGNED NULL,
    error_summary TEXT NULL,

    PRIMARY KEY (collection_run_id),

    CONSTRAINT chk_collection_runs_data_origin
        CHECK (data_origin IN ('synthetic', 'aws')),

    CONSTRAINT chk_collection_runs_status
        CHECK (status IN ('success', 'partial', 'failure')),

    CONSTRAINT chk_collection_runs_timestamps
    CHECK (finished_at IS NULL OR finished_at >= started_at)

)   ENGINE = InnoDB
    DEFAULT CHARACTER SET = utf8mb4
    COLLATE = utf8mb4_0900_ai_ci;