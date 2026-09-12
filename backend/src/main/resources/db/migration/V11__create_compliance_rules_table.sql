CREATE TABLE compliance_rules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    rule_code VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    category VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    weight DECIMAL(5,2) NOT NULL,
    expression TEXT NOT NULL,
    version INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    evidence_required BOOLEAN NOT NULL DEFAULT FALSE,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uk_compliance_rules_rule_code UNIQUE (rule_code),
    CONSTRAINT fk_compliance_rules_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT chk_compliance_rules_severity CHECK (severity IN ('MANDATORY','WARNING'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_compliance_rules_is_active ON compliance_rules(is_active);
CREATE INDEX idx_compliance_rules_category ON compliance_rules(category);
