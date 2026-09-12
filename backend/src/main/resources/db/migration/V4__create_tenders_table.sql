CREATE TABLE tenders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reference_number VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT NULL,
    eligibility_criteria TEXT NULL,
    closing_date TIMESTAMP NOT NULL,
    status VARCHAR(30) NOT NULL,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uk_tenders_reference_number UNIQUE (reference_number),
    CONSTRAINT fk_tenders_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT chk_tenders_status CHECK (status IN ('DRAFT','OPEN','CLOSED','CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
