-- Create tables for DuckDB
CREATE TABLE IF NOT EXISTS risk_assessments (
    id INTEGER PRIMARY KEY,
    assessment_name VARCHAR,
    cloud_provider VARCHAR,
    assessment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    risk_score DECIMAL(5,2),
    status VARCHAR DEFAULT 'pending'
);
DESCRIBE risk_assessments;
CHECKPOINT;
CREATE TABLE IF NOT EXISTS security_findings (
    id INTEGER PRIMARY KEY,
    risk_assessment_id INTEGER,
    finding_name VARCHAR,
    severity VARCHAR,
    description VARCHAR,
    remediation_steps VARCHAR,
    status VARCHAR DEFAULT 'open',
    FOREIGN KEY (risk_assessment_id) REFERENCES risk_assessments(id)
);
DESCRIBE security_findings;
CHECKPOINT;
CREATE TABLE IF NOT EXISTS cloud_resources (
    id INTEGER PRIMARY KEY,
    resource_name VARCHAR,
    resource_type VARCHAR,
    cloud_provider VARCHAR,
    region VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DESCRIBE cloud_resources;
CHECKPOINT;
-- Insert sample data only if it doesn't exist
INSERT OR IGNORE INTO risk_assessments (id, assessment_name, cloud_provider, risk_score, status)
VALUES 
    (1, 'AWS Production Assessment', 'AWS', 75.5, 'completed'),
    (2, 'Azure Development Assessment', 'Azure', 60.0, 'in_progress'),
    (3, 'Azure Production Assessment', 'Azure', 85.0, 'completed');
SELECT * FROM risk_assessments;
CHECKPOINT;
INSERT OR IGNORE INTO security_findings (id, risk_assessment_id, finding_name, severity, description, status)
VALUES 
    (1, 1, 'Public S3 Bucket', 'High', 'S3 bucket is publicly accessible', 'open'),
    (2, 1, 'Unencrypted EBS Volume', 'Medium', 'EBS volume is not encrypted', 'open'),
    (3, 2, 'Unencrypted AzureFS Volume', 'Medium', 'AzureFS volume is not encrypted', 'open'),
    (4, 3, 'Public Azure Storage', 'High', 'Azure Storage account is publicly accessible', 'open');
SELECT * FROM security_findings;
CHECKPOINT;
INSERT OR IGNORE INTO cloud_resources (id, resource_name, resource_type, cloud_provider, region)
VALUES 
    (1, 'prod-database', 'RDS', 'AWS', 'us-east-1'),
    (2, 'dev-storage', 'Blob Storage', 'Azure', 'eastus'),
    (3, 'prod-storage', 'Blob Storage', 'Azure', 'eastus');
SELECT * FROM cloud_resources;
CHECKPOINT;