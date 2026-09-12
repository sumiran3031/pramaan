CREATE TABLE bids (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tender_id BIGINT NOT NULL,
    bidder_id BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL,
    submitted_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uk_bids_tender_bidder UNIQUE (tender_id, bidder_id),
    CONSTRAINT fk_bids_tender FOREIGN KEY (tender_id) REFERENCES tenders(id),
    CONSTRAINT fk_bids_bidder FOREIGN KEY (bidder_id) REFERENCES users(id),
    CONSTRAINT chk_bids_status CHECK (status IN ('DRAFT','SUBMITTED','UNDER_REVIEW','QUALIFIED','DISQUALIFIED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_bids_status ON bids(status);
CREATE INDEX idx_bids_tender_id ON bids(tender_id);
