CREATE TABLE rule_results (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    compliance_result_id BIGINT NOT NULL,
    rule_id BIGINT NOT NULL,
    rule_version INT NOT NULL,
    rule_name VARCHAR(255) NOT NULL,
    rule_expression TEXT NOT NULL,
    result VARCHAR(20) NOT NULL,
    score_impact DECIMAL(5,2) NOT NULL,
    evidence TEXT NULL,
    explanation TEXT NULL,
    evaluated_at TIMESTAMP NOT NULL,
    CONSTRAINT uk_rule_results_result_rule UNIQUE (compliance_result_id, rule_id),
    CONSTRAINT fk_rule_results_compliance_result FOREIGN KEY (compliance_result_id) REFERENCES compliance_results(id),
    CONSTRAINT fk_rule_results_rule FOREIGN KEY (rule_id) REFERENCES compliance_rules(id),
    CONSTRAINT chk_rule_results_result CHECK (result IN ('PASS','FAIL','WARNING','NOT_EVALUATED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_rule_results_compliance_result_id ON rule_results(compliance_result_id);
