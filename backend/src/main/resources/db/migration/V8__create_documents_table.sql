CREATE TABLE documents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    bid_id BIGINT NOT NULL,
    document_type_id BIGINT NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    storage_key VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL,
    uploaded_by BIGINT NOT NULL,
    is_replaced BOOLEAN NOT NULL DEFAULT FALSE,
    replaced_by_document_id BIGINT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_documents_bid FOREIGN KEY (bid_id) REFERENCES bids(id),
    CONSTRAINT fk_documents_document_type FOREIGN KEY (document_type_id) REFERENCES document_types(id),
    CONSTRAINT fk_documents_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(id),
    CONSTRAINT fk_documents_replaced_by FOREIGN KEY (replaced_by_document_id) REFERENCES documents(id),
    CONSTRAINT chk_documents_status CHECK (status IN ('UPLOADED','PROCESSING','PROCESSED','FAILED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_documents_bid_id ON documents(bid_id);
CREATE INDEX idx_documents_document_type_id ON documents(document_type_id);
CREATE INDEX idx_documents_status ON documents(status);
