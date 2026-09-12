CREATE TABLE extracted_fields (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    extraction_id BIGINT NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    extracted_value TEXT NULL,
    normalized_value TEXT NULL,
    confidence_score DECIMAL(5,4) NOT NULL,
    is_manually_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    corrected_value TEXT NULL,
    corrected_by BIGINT NULL,
    corrected_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_extracted_fields_extraction_field UNIQUE (extraction_id, field_name),
    CONSTRAINT fk_extracted_fields_extraction FOREIGN KEY (extraction_id) REFERENCES document_extractions(id),
    CONSTRAINT fk_extracted_fields_corrected_by FOREIGN KEY (corrected_by) REFERENCES users(id),
    CONSTRAINT chk_extracted_fields_confidence CHECK (confidence_score >= 0.0000 AND confidence_score <= 1.0000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_extracted_fields_extraction_id ON extracted_fields(extraction_id);
