# PRAMAAN - Entity Relationship Diagram

Status: LOCKED (Day 2)

This diagram shows all 14 entities in the PRAMAAN schema and their
relationships. It renders directly on GitHub via Mermaid.

For full column definitions, types, constraints, indexes, and business
rules, see database-design.md in this same folder. This file focuses
on structure and relationships only.

---

## Mermaid ER Diagram

```mermaid
erDiagram
    ROLES ||--o{ USERS : "has"
    USERS ||--o{ TENDERS : "creates"
    USERS ||--o{ BIDS : "submits"
    TENDERS ||--o{ BIDS : "receives"
    BIDS ||--o{ DOCUMENTS : "contains"
    DOCUMENT_TYPES ||--o{ DOCUMENTS : "classifies"
    USERS ||--o{ DOCUMENTS : "uploads"
    DOCUMENTS ||--o{ DOCUMENTS : "replaced by"
    DOCUMENTS ||--o{ DOCUMENT_EXTRACTIONS : "has"
    DOCUMENT_EXTRACTIONS ||--o{ EXTRACTED_FIELDS : "produces"
    USERS ||--o{ EXTRACTED_FIELDS : "corrects"
    BIDS ||--o{ COMPLIANCE_RESULTS : "evaluated as"
    COMPLIANCE_RESULTS ||--o{ RULE_RESULTS : "breaks down into"
    COMPLIANCE_RULES ||--o{ RULE_RESULTS : "evaluated by"
    USERS ||--o{ COMPLIANCE_RULES : "authors"
    BIDS ||--o{ OFFICER_REVIEWS : "reviewed as"
    USERS ||--o{ OFFICER_REVIEWS : "reviews as officer"
    COMPLIANCE_RESULTS ||--o{ OFFICER_REVIEWS : "referenced by"
    BIDS ||--o{ VERIFICATION_RESULTS : "verified as"
    DOCUMENTS ||--o{ VERIFICATION_RESULTS : "verified against"
    USERS ||--o{ AUDIT_LOGS : "acts in"

    ROLES {
        bigint id PK
        varchar name UK
    }
    USERS {
        bigint id PK
        varchar email UK
        varchar password_hash
        varchar full_name
        bigint role_id FK
        boolean is_active
    }
    TENDERS {
        bigint id PK
        varchar reference_number UK
        varchar title
        varchar status
        bigint created_by FK
    }
    BIDS {
        bigint id PK
        bigint tender_id FK
        bigint bidder_id FK
        varchar status
    }
    DOCUMENT_TYPES {
        bigint id PK
        varchar code UK
        varchar display_name
        boolean is_active
    }
    DOCUMENTS {
        bigint id PK
        bigint bid_id FK
        bigint document_type_id FK
        bigint uploaded_by FK
        bigint replaced_by_document_id FK
        varchar status
        boolean is_replaced
    }
    DOCUMENT_EXTRACTIONS {
        bigint id PK
        bigint document_id FK
        int attempt_number
        varchar status
        boolean is_current
    }
    EXTRACTED_FIELDS {
        bigint id PK
        bigint extraction_id FK
        varchar field_name
        decimal confidence_score
        bigint corrected_by FK
    }
    COMPLIANCE_RULES {
        bigint id PK
        varchar rule_code UK
        varchar severity
        decimal weight
        text expression
        int version
        bigint created_by FK
    }
    COMPLIANCE_RESULTS {
        bigint id PK
        bigint bid_id FK
        decimal overall_score
        varchar risk_level
        varchar compliance_status
        boolean is_current
    }
    RULE_RESULTS {
        bigint id PK
        bigint compliance_result_id FK
        bigint rule_id FK
        int rule_version
        varchar result
        decimal score_impact
    }
    OFFICER_REVIEWS {
        bigint id PK
        bigint bid_id FK
        bigint officer_id FK
        bigint compliance_result_id FK
        varchar decision
        boolean is_override
        text override_reason
    }
    VERIFICATION_RESULTS {
        bigint id PK
        bigint bid_id FK
        bigint document_id FK
        varchar provider_type
        varchar verification_mode
        varchar status
    }
    AUDIT_LOGS {
        bigint id PK
        bigint actor_id FK
        varchar actor_role
        varchar action
        varchar entity_type
        bigint entity_id
    }
```

---

## Reading Notes

- `entity_type` / `entity_id` on AUDIT_LOGS are intentionally not a
  foreign key relationship (see database-design.md for rationale), so
  no direct edge is drawn from AUDIT_LOGS to every other entity here.
  Conceptually, AUDIT_LOGS can reference any entity in this diagram.
- The self-referencing DOCUMENTS -> DOCUMENTS edge represents the
  optional document-replacement link (replaced_by_document_id).
- is_current (on DOCUMENT_EXTRACTIONS and COMPLIANCE_RESULTS) and
  bids.status (the authoritative decision pointer) are business rules
  enforced at the application layer, not visible as diagram
  constraints - see database-design.md for the full explanation.
