CREATE TABLE verification_results (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    bid_id BIGINT NOT NULL,
    document_id BIGINT NULL,
    provider_type VARCHAR(50) NOT NULL,
    verification_mode VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    response_payload JSON NULL,
    verified_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_verification_results_bid FOREIGN KEY (bid_id) REFERENCES bids(id),
    CONSTRAINT fk_verification_results_document FOREIGN KEY (document_id) REFERENCES documents(id),
    CONSTRAINT chk_verification_results_mode CHECK (verification_mode IN ('MOCK','LIVE')),
    CONSTRAINT chk_verification_results_status CHECK (status IN ('VERIFIED','FAILED','NOT_AVAILABLE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_verification_results_bid_id ON verification_results(bid_id);
CREATE INDEX idx_verification_results_provider_mode ON verification_results(provider_type, verification_mode);
