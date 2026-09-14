CREATE TABLE instances (
    instance_pk BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    aws_account_id CHAR(12) NOT NULL,
    aws_region VARCHAR(32) NOT NULL,
    ec2_instance_id VARCHAR(32) NOT NULL,

    availability_zone VARCHAR(32) NOT NULL,
    current_instance_type VARCHAR(64) NOT NULL,
    architecture VARCHAR(32) NOT NULL,
    lifecycle_state VARCHAR(32) NOT NULL,

    project_tag VARCHAR(128) NOT NULL,
    environment_tag VARCHAR(128) NULL,
    owner_tag VARCHAR(128) NULL,
    workload_tag VARCHAR(128) NULL,
    managed_by_tag VARCHAR(128) NULL,
    tags_json JSON NOT NULL,

    first_seen_at DATETIME(6) NOT NULL,
    last_seen_at DATETIME(6) NOT NULL,
    data_origin VARCHAR(16) NOT NULL,

    PRIMARY KEY(instance_pk),

    CONSTRAINT chk_instances_aws_account_id_length
        CHECK (CHAR_LENGTH(aws_account_id) = 12),

    CONSTRAINT chk_instances_ec2_id_prefix
        CHECK (ec2_instance_id COLLATE utf8mb4_0900_as_cs LIKE 'i-%'),

    CONSTRAINT uq_instances_aws_identity 
        UNIQUE (aws_account_id, aws_region, ec2_instance_id),

    CONSTRAINT chk_instances_data_origin
        CHECK (data_origin IN ('synthetic', 'aws')),

    CONSTRAINT chk_instances_timestamps
        CHECK (last_seen_at >= first_seen_at)

) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;
