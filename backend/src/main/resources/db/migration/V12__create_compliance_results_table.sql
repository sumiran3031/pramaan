CREATE TABLE compliance_results (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    bid_id BIGINT NOT NULL,
    overall_score DECIMAL(5,2) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    compliance_status VARCHAR(30) NOT NULL,
    cross_document_issues JSON NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    evaluated_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_compliance_results_bid FOREIGN KEY (bid_id) REFERENCES bids(id),
    CONSTRAINT chk_compliance_results_risk CHECK (risk_level IN ('LOW','MEDIUM','HIGH')),
    CONSTRAINT chk_compliance_results_status CHECK (compliance_status IN ('COMPLIANT','NON_COMPLIANT','PARTIALLY_COMPLIANT')),
    CONSTRAINT chk_compliance_results_score CHECK (overall_score >= 0 AND overall_score <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_compliance_results_bid_current ON compliance_results(bid_id, is_current);
