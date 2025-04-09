-- Create schemas
CREATE SCHEMA IF NOT EXISTS cloud_risk_portal_rag_data;

-- Set search path
SET search_path TO cloud_risk_portal_rag_data;

-- Create tables
CREATE TABLE IF NOT EXISTS cloud_risk_portal_rag_data.risk_assessments (
    id SERIAL PRIMARY KEY,
    assessment_name VARCHAR(255) NOT NULL,
    cloud_provider VARCHAR(100) NOT NULL,
    assessment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    risk_score DECIMAL(5,2),
    status VARCHAR(50) DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS cloud_risk_portal_rag_data.security_findings (
    id SERIAL PRIMARY KEY,
    risk_assessment_id INTEGER REFERENCES cloud_risk_portal_rag_data.risk_assessments(id),
    finding_name VARCHAR(255) NOT NULL,
    severity VARCHAR(50) NOT NULL,
    description TEXT,
    remediation_steps TEXT,
    status VARCHAR(50) DEFAULT 'open'
);

CREATE TABLE IF NOT EXISTS cloud_risk_portal_rag_data.cloud_resources (
    id SERIAL PRIMARY KEY,
    resource_name VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    cloud_provider VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_risk_assessments_cloud_provider ON cloud_risk_portal_rag_data.risk_assessments(cloud_provider);
CREATE INDEX IF NOT EXISTS idx_security_findings_assessment_id ON cloud_risk_portal_rag_data.security_findings(risk_assessment_id);
CREATE INDEX IF NOT EXISTS idx_cloud_resources_type ON cloud_risk_portal_rag_data.cloud_resources(resource_type);

-- Insert sample data
INSERT INTO cloud_risk_portal_rag_data.risk_assessments (assessment_name, cloud_provider, risk_score, status)
VALUES 
    ('AWS Production Assessment', 'AWS', 75.5, 'completed'),
    ('Azure Development Assessment', 'Azure', 60.0, 'in_progress'),
    ('Azure Production Assessment', 'Azure', 85.0, 'completed');

-- Insert security findings with valid risk_assessment_id references
INSERT INTO cloud_risk_portal_rag_data.security_findings (risk_assessment_id, finding_name, severity, description, status)
VALUES 
    (1, 'Public S3 Bucket', 'High', 'S3 bucket is publicly accessible', 'open'),
    (1, 'Unencrypted EBS Volume', 'Medium', 'EBS volume is not encrypted', 'open'),
    (2, 'Unencrypted AzureFS Volume', 'Medium', 'AzureFS volume is not encrypted', 'open'),
    (3, 'Public Azure Storage', 'High', 'Azure Storage account is publicly accessible', 'open');

-- Insert cloud resources
INSERT INTO cloud_risk_portal_rag_data.cloud_resources (resource_name, resource_type, cloud_provider, region)
VALUES 
    ('prod-database', 'RDS', 'AWS', 'us-east-1'),
    ('dev-storage', 'Blob Storage', 'Azure', 'eastus'),
    ('prod-storage', 'Blob Storage', 'Azure', 'eastus'); 
