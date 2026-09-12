CREATE TABLE document_extractions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_id BIGINT NOT NULL,
    attempt_number INT NOT NULL,
    ocr_engine VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL,
    raw_ocr_text LONGTEXT NULL,
    error_message TEXT NULL,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uk_document_extractions_document_attempt UNIQUE (document_id, attempt_number),
    CONSTRAINT fk_document_extractions_document FOREIGN KEY (document_id) REFERENCES documents(id),
    CONSTRAINT chk_document_extractions_status CHECK (status IN ('PENDING','PROCESSING','COMPLETED','FAILED')),
    CONSTRAINT chk_document_extractions_current_completed CHECK (is_current = FALSE OR status = 'COMPLETED')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_document_extractions_status ON document_extractions(status);
CREATE INDEX idx_document_extractions_document_current ON document_extractions(document_id, is_current);
