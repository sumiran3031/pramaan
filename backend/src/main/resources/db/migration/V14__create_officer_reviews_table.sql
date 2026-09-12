CREATE TABLE officer_reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    bid_id BIGINT NOT NULL,
    officer_id BIGINT NOT NULL,
    compliance_result_id BIGINT NOT NULL,
    decision VARCHAR(30) NOT NULL,
    is_override BOOLEAN NOT NULL DEFAULT FALSE,
    override_reason TEXT NULL,
    officer_notes TEXT NULL,
    reviewed_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_officer_reviews_bid FOREIGN KEY (bid_id) REFERENCES bids(id),
    CONSTRAINT fk_officer_reviews_officer FOREIGN KEY (officer_id) REFERENCES users(id),
    CONSTRAINT fk_officer_reviews_compliance_result FOREIGN KEY (compliance_result_id) REFERENCES compliance_results(id),
    CONSTRAINT chk_officer_reviews_decision CHECK (decision IN ('QUALIFIED','DISQUALIFIED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_officer_reviews_bid_id ON officer_reviews(bid_id);
CREATE INDEX idx_officer_reviews_officer_id ON officer_reviews(officer_id);
