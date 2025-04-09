-- Create schema
CREATE SCHEMA IF NOT EXISTS cloud_risk_portal_rag_data;

-- Create tables
CREATE TABLE IF NOT EXISTS cloud_risk_portal_rag_data.risk_assessments (
    id BIGINT,
    assessment_name VARCHAR,
    cloud_provider VARCHAR,
    assessment_date TIMESTAMP,
    risk_score DOUBLE,
    status VARCHAR
) WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['cloud_provider']
);

CREATE TABLE IF NOT EXISTS cloud_risk_portal_rag_data.security_findings (
    id BIGINT,
    risk_assessment_id BIGINT,
    finding_name VARCHAR,
    severity VARCHAR,
    description VARCHAR,
    remediation_steps VARCHAR,
    status VARCHAR
) WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['severity']
);

CREATE TABLE IF NOT EXISTS cloud_risk_portal_rag_data.cloud_resources (
    id BIGINT,
    resource_name VARCHAR,
    resource_type VARCHAR,
    cloud_provider VARCHAR,
    region VARCHAR,
    created_at TIMESTAMP
) WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['cloud_provider']
);

-- Insert sample data
INSERT INTO cloud_risk_portal_rag_data.risk_assessments 
VALUES 
    (1, 'AWS Production Assessment', 'AWS', CURRENT_TIMESTAMP, 75.5, 'completed'),
    (2, 'Azure Development Assessment', 'Azure', CURRENT_TIMESTAMP, 60.0, 'in_progress'),
    (3, 'Azure Production Assessment', 'Azure', CURRENT_TIMESTAMP, 85.0, 'completed');

INSERT INTO cloud_risk_portal_rag_data.security_findings 
VALUES 
    (1, 1, 'Public S3 Bucket', 'High', 'S3 bucket is publicly accessible', 'Fix bucket permissions', 'open'),
    (2, 1, 'Unencrypted EBS Volume', 'Medium', 'EBS volume is not encrypted', 'Enable encryption', 'open'),
    (3, 2, 'Unencrypted AzureFS Volume', 'Medium', 'AzureFS volume is not encrypted', 'Enable encryption', 'open'),
    (4, 3, 'Public Azure Storage', 'High', 'Azure Storage account is publicly accessible', 'Fix storage permissions', 'open');

INSERT INTO cloud_risk_portal_rag_data.cloud_resources 
VALUES 
    (1, 'prod-database', 'RDS', 'AWS', 'us-east-1', CURRENT_TIMESTAMP),
    (2, 'dev-storage', 'Blob Storage', 'Azure', 'eastus', CURRENT_TIMESTAMP),
    (3, 'prod-storage', 'Blob Storage', 'Azure', 'eastus', CURRENT_TIMESTAMP); 