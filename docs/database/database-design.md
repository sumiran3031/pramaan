# PRAMAAN - Database Design

Status: LOCKED (Day 2)
Database: MySQL 8.0
Schema management: Flyway (versioned migrations, decided Day 2)

This document is the single source of truth for the PRAMAAN relational
schema. It covers all 14 tables, their columns, types, keys, indexes,
enumerated status values, cardinalities, and the cross-cutting business
rules that are enforced at the application layer rather than the
database layer.

---

## Core Principle

AI assessment (compliance_results) is evidence and recommendation.
The Procurement Officer's decision (bids.status, officer_reviews) is
the final procurement outcome. These are structurally separate
throughout this schema and must never be merged or confused.

Flow:
Rules -> Rule Results -> Compliance Assessment -> Officer Review ->
Optional Override + Reason -> Final Bid Status

---

## 1. roles

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| name | VARCHAR(50) | UNIQUE, NOT NULL |

Values: BIDDER, OFFICER, ADMIN

---

## 2. users

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| email | VARCHAR(255) | UNIQUE, NOT NULL |
| password_hash | VARCHAR(255) | NOT NULL |
| full_name | VARCHAR(255) | NOT NULL |
| role_id | BIGINT | FK -> roles.id, NOT NULL |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

Business rules (application layer):
- Emails normalized to lowercase before persistence.
- Passwords stored only as BCrypt hashes, never plaintext.

Cardinality: roles (1) -> users (N)

---

## 3. tenders

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| reference_number | VARCHAR(100) | UNIQUE, NOT NULL |
| title | VARCHAR(500) | NOT NULL |
| description | TEXT | NULL |
| eligibility_criteria | TEXT | NULL |
| closing_date | TIMESTAMP | NOT NULL |
| status | VARCHAR(30) | NOT NULL |
| created_by | BIGINT | FK -> users.id, NOT NULL |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

Status values: DRAFT, OPEN, CLOSED, CANCELLED

Note: eligibility_criteria remains free-text. Structured rule logic
belongs to compliance_rules, avoiding duplicated rule logic in two
places.

Cardinality: users (1) -> tenders (N) [creator]

---

## 4. bids

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| tender_id | BIGINT | FK -> tenders.id, NOT NULL |
| bidder_id | BIGINT | FK -> users.id, NOT NULL |
| status | VARCHAR(30) | NOT NULL |
| submitted_at | TIMESTAMP | NULL (null while DRAFT) |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

Status values: DRAFT, SUBMITTED, UNDER_REVIEW, QUALIFIED, DISQUALIFIED

Constraints:
- UNIQUE (tender_id, bidder_id) - one bid record per bidder per tender
- INDEX (status)
- INDEX (tender_id)

Business rules (application layer):
- bidder_id must reference a user with role BIDDER.
- bids.status is the single authoritative current decision state for
  a bid. QUALIFIED / DISQUALIFIED represent the Officer's final
  decision, never the AI assessment.

Cardinality: tenders (1) -> bids (N); users (1) -> bids (N) [bidder]

---

## 5. document_types

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| code | VARCHAR(50) | UNIQUE, NOT NULL |
| display_name | VARCHAR(150) | NOT NULL |
| description | TEXT | NULL |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

Initial codes: GST, PAN, UDYAM, EPFO_ESIC, STARTUP_INDIA, NSIC,
OEM_AUTHORIZATION, MAKE_IN_INDIA, TENDER_SPECIFIC, OTHER

This is reference data, not a Java enum, so Admin can add or retire
document types without a code deployment.

---

## 6. documents

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| bid_id | BIGINT | FK -> bids.id, NOT NULL |
| document_type_id | BIGINT | FK -> document_types.id, NOT NULL |
| original_filename | VARCHAR(255) | NOT NULL |
| storage_key | VARCHAR(500) | NOT NULL |
| mime_type | VARCHAR(100) | NOT NULL |
| file_size_bytes | BIGINT | NOT NULL |
| status | VARCHAR(30) | NOT NULL |
| uploaded_by | BIGINT | FK -> users.id, NOT NULL |
| is_replaced | BOOLEAN | NOT NULL, DEFAULT FALSE |
| replaced_by_document_id | BIGINT | FK -> documents.id (self), NULL |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

Status values: UPLOADED, PROCESSING, PROCESSED, FAILED

Constraints:
- INDEX (bid_id)
- INDEX (document_type_id)
- INDEX (status)

Business rules (application layer, not DB CHECK constraints):
- MIME type, extension, file signature/content, and file-size
  validation happen at the service layer. The backend must never
  blindly trust client-provided MIME type or extension.
- Replacement semantics: original document row is never physically
  deleted. When replaced: is_replaced = TRUE on the old row,
  replaced_by_document_id points to the new row, and the new row has
  is_replaced = FALSE. Replacement is recorded in audit_logs.
- No checksum/hash column in this phase; may be added via a future
  migration if a concrete need arises.

Cardinality: bids (1) -> documents (N); document_types (1) ->
documents (N); users (1) -> documents (N) [uploader]; documents (1) ->
documents (N) [optional self-referencing replacement]

---

## 7. document_extractions

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| document_id | BIGINT | FK -> documents.id, NOT NULL |
| attempt_number | INT | NOT NULL |
| ocr_engine | VARCHAR(50) | NOT NULL |
| status | VARCHAR(30) | NOT NULL |
| raw_ocr_text | LONGTEXT | NULL |
| error_message | TEXT | NULL |
| started_at | TIMESTAMP | NULL |
| completed_at | TIMESTAMP | NULL |
| created_at | TIMESTAMP | NOT NULL |
| is_current | BOOLEAN | NOT NULL, DEFAULT FALSE |

Status values: PENDING, PROCESSING, COMPLETED, FAILED

Constraints:
- UNIQUE (document_id, attempt_number)
- INDEX (document_id)
- INDEX (status)
- INDEX (document_id, is_current)

Business rules (application layer, enforced transactionally):
- Only one extraction per document may have is_current = TRUE at any
  time. A new successful extraction becomes current; the previous
  current extraction is set to FALSE in the same transaction.
- Only status = COMPLETED extractions may ever have is_current = TRUE.
  PENDING, PROCESSING, and FAILED attempts must never be treated as
  authoritative input for downstream compliance evaluation.
- raw_ocr_text is retained in full for debugging, traceability, and
  explaining extraction results to officers.

Cardinality: documents (1) -> document_extractions (N)

---

## 8. extracted_fields

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| extraction_id | BIGINT | FK -> document_extractions.id, NOT NULL |
| field_name | VARCHAR(100) | NOT NULL |
| extracted_value | TEXT | NULL |
| normalized_value | TEXT | NULL |
| confidence_score | DECIMAL(5,4) | NOT NULL, range 0.0000-1.0000 |
| is_manually_corrected | BOOLEAN | NOT NULL, DEFAULT FALSE |
| corrected_value | TEXT | NULL |
| corrected_by | BIGINT | FK -> users.id, NULL |
| corrected_at | TIMESTAMP | NULL |
| created_at | TIMESTAMP | NOT NULL |

Constraints:
- UNIQUE (extraction_id, field_name)
- INDEX (extraction_id)

Business rules (application layer):
- Confidence tiers: >= 0.85 auto-accept, 0.60-0.84 warning/review,
  < 0.60 manual review required.
- Single-slot correction model (no separate correction-history table
  in this phase). normalized_value must be recomputed from
  corrected_value whenever a correction is made.
- Every manual correction must generate a FIELD_MANUALLY_CORRECTED
  audit_logs event recording who changed what and when.

Cardinality: document_extractions (1) -> extracted_fields (N); users
(1) -> extracted_fields (N) [corrector, optional]

---

## 9. compliance_rules

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| rule_code | VARCHAR(100) | UNIQUE, NOT NULL |
| name | VARCHAR(255) | NOT NULL |
| description | TEXT | NULL |
| category | VARCHAR(50) | NOT NULL |
| severity | VARCHAR(20) | NOT NULL |
| weight | DECIMAL(5,2) | NOT NULL |
| expression | TEXT | NOT NULL |
| version | INT | NOT NULL, DEFAULT 1 |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| evidence_required | BOOLEAN | NOT NULL, DEFAULT FALSE |
| created_by | BIGINT | FK -> users.id, NOT NULL |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

Severity values: MANDATORY, WARNING

Constraints:
- INDEX (is_active)
- INDEX (category)

Business rules (application layer):
- Rules are data-driven and configurable, never hardcoded in Java or
  React.
- expression is a SpEL expression, evaluated only through a
  locked-down SimpleEvaluationContext: no method invocation, no bean
  access, no static access. This is a security-critical control.

Cardinality: users (1) -> compliance_rules (N) [author]

---

## 10. compliance_results

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| bid_id | BIGINT | FK -> bids.id, NOT NULL |
| overall_score | DECIMAL(5,2) | NOT NULL, 0-100 |
| risk_level | VARCHAR(20) | NOT NULL |
| compliance_status | VARCHAR(30) | NOT NULL |
| cross_document_issues | JSON | NULL |
| is_current | BOOLEAN | NOT NULL, DEFAULT FALSE |
| evaluated_at | TIMESTAMP | NOT NULL |
| created_at | TIMESTAMP | NOT NULL |

Risk values: LOW, MEDIUM, HIGH
Status values: COMPLIANT, NON_COMPLIANT, PARTIALLY_COMPLIANT

Constraints:
- INDEX (bid_id, is_current)

Business rules (application layer, enforced transactionally):
- compliance_status is the AI/system assessment. It is completely
  separate from bids.status, which is the Officer's final decision.
- Only one compliance_results row per bid may have is_current = TRUE
  at any time. Re-evaluation creates a new row; the previous current
  row is set to FALSE in the same transaction.
- cross_document_issues is stored as JSON rather than a separate
  table because it is fully recomputed on each evaluation run.
- Re-evaluation events (e.g. triggered by a document replacement or a
  manual field correction) are recorded in audit_logs, including the
  reason where applicable. No separate re-evaluation event table
  exists.

Cardinality: bids (1) -> compliance_results (N)

---

## 11. rule_results

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| compliance_result_id | BIGINT | FK -> compliance_results.id, NOT NULL |
| rule_id | BIGINT | FK -> compliance_rules.id, NOT NULL |
| rule_version | INT | NOT NULL |
| rule_name | VARCHAR(255) | NOT NULL |
| rule_expression | TEXT | NOT NULL |
| result | VARCHAR(20) | NOT NULL |
| score_impact | DECIMAL(5,2) | NOT NULL |
| evidence | TEXT | NULL |
| explanation | TEXT | NULL |
| evaluated_at | TIMESTAMP | NOT NULL |

Result values: PASS, FAIL, WARNING, NOT_EVALUATED

Constraints:
- UNIQUE (compliance_result_id, rule_id)
- INDEX (compliance_result_id)

Business rules:
- rule_version, rule_name, and rule_expression are a full snapshot of
  the rule exactly as it was evaluated. Because compliance_rules rows
  are mutable (a rule's expression can change on edit), the version
  number alone is not sufficient to reconstruct history - the
  snapshot fields make each rule_results row self-contained and
  audit-complete without a separate rule-versions table.

Cardinality: compliance_results (1) -> rule_results (N);
compliance_rules (1) -> rule_results (N)

---

## 12. officer_reviews

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| bid_id | BIGINT | FK -> bids.id, NOT NULL |
| officer_id | BIGINT | FK -> users.id, NOT NULL |
| compliance_result_id | BIGINT | FK -> compliance_results.id, NOT NULL |
| decision | VARCHAR(30) | NOT NULL |
| is_override | BOOLEAN | NOT NULL, DEFAULT FALSE |
| override_reason | TEXT | NULL |
| officer_notes | TEXT | NULL |
| reviewed_at | TIMESTAMP | NOT NULL |
| created_at | TIMESTAMP | NOT NULL |

Decision values: QUALIFIED, DISQUALIFIED

Constraints:
- INDEX (bid_id)
- INDEX (officer_id)

Business rules (application layer):
- officer_id must reference a user with role OFFICER. A BIDDER must
  never be able to create or finalize an officer review.
- override_reason is nullable at the database level but MUST be
  provided and non-blank whenever is_override = TRUE, enforced in the
  service layer.
- officer_reviews is append-only history. There is no is_current or
  is_final flag on this table. bids.status is the single authoritative
  current decision; officer_reviews is the complete review history
  behind it.
- When creating a new officer review: bid_id must match
  compliance_results.bid_id, and the referenced compliance_result_id
  must be the current authoritative result for that bid at review
  time. Any future "reopened review" exception must go through an
  explicitly authorized workflow, not an implicit rule.
- The final QUALIFIED / DISQUALIFIED bid status may only change
  through this authorized officer decision workflow.

Cardinality: bids (1) -> officer_reviews (N); users (1) ->
officer_reviews (N) [officer]; compliance_results (1) ->
officer_reviews (N)

---

## 13. verification_results

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| bid_id | BIGINT | FK -> bids.id, NOT NULL |
| document_id | BIGINT | FK -> documents.id, NULL |
| provider_type | VARCHAR(50) | NOT NULL |
| verification_mode | VARCHAR(20) | NOT NULL |
| status | VARCHAR(30) | NOT NULL |
| response_payload | JSON | NULL |
| verified_at | TIMESTAMP | NOT NULL |
| created_at | TIMESTAMP | NOT NULL |

Mode values: MOCK, LIVE
Status values: VERIFIED, FAILED, NOT_AVAILABLE

Constraints:
- INDEX (bid_id)
- INDEX (provider_type, verification_mode)

Business rules:
- Append-only. Re-running a verification creates a new row rather than
  overwriting a previous one, preserving full verification history.
- verification_mode must always be explicit. In the current project,
  all government verification is MOCK/simulated. LIVE is reserved for
  a future authorized integration and must never be fabricated.

Cardinality: bids (1) -> verification_results (N); documents (1) ->
verification_results (N) [optional]

---

## 14. audit_logs

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| actor_id | BIGINT | FK -> users.id, NULL |
| actor_role | VARCHAR(20) | NOT NULL |
| action | VARCHAR(100) | NOT NULL |
| entity_type | VARCHAR(50) | NOT NULL |
| entity_id | BIGINT | NOT NULL, no FK (deliberate) |
| metadata | JSON | NULL |
| reason | TEXT | NULL |
| ip_address | VARCHAR(45) | NULL |
| created_at | TIMESTAMP | NOT NULL |

Example action values: BID_CREATED, DOCUMENT_UPLOADED,
DOCUMENT_REPLACED, EXTRACTION_COMPLETED, FIELD_MANUALLY_CORRECTED,
COMPLIANCE_EVALUATED, RULE_CREATED, RULE_UPDATED,
OFFICER_REVIEW_CREATED, OFFICER_OVERRIDE, VERIFICATION_PERFORMED,
LOGIN

Constraints:
- INDEX (entity_type, entity_id)
- INDEX (actor_id)
- INDEX (action)
- INDEX (created_at)

Business rules:
- audit_logs is append-only and immutable. No update operation and no
  delete operation are ever exposed at the application layer. There is
  no updated_at column.
- entity_type + entity_id intentionally has no foreign key. Audit
  events span many different entity types, and a real FK would tie
  this table to one entity type or introduce fragile lazy-loaded
  relationships. This is a deliberate design trade-off: the audit log
  must remain a simple, dumb, reliable append target that can never
  fail to insert because a related row is missing or evicted.
- actor_role is a historical snapshot captured at the time of the
  action. It must never be dynamically derived from the user's
  current role, since a user's role could change after the action was
  recorded.
- actor_id may be NULL for system-generated events.
- LOGIN events are recorded here rather than in a separate login-log
  table, to keep the audit trail unfragmented. Authentication
  failures/suspicious activity may additionally be handled by
  application/security logging in a later phase.
- No retention, archival, or partitioning mechanism exists yet. This
  is a known, accepted future production concern, not a Day 2 gap.

Cardinality: users (1) -> audit_logs (N) [actor, optional]

---

## Cross-Cutting Business Rules Summary

- Emails normalized to lowercase before persistence.
- Passwords stored only as BCrypt hashes.
- Role-correctness of bidder_id / officer_id / created_by is validated
  in the service layer, not by database constraints.
- File MIME type, extension, and signature validation happen in the
  service layer; client-provided MIME type is never trusted blindly.
- override_reason is required and non-blank whenever is_override =
  TRUE, enforced in the service layer.
- SpEL rule expressions are evaluated only through a locked-down
  SimpleEvaluationContext (no method calls, no bean access).
- The AI assessment (compliance_results) is always structurally
  distinct from the Officer's final decision (bids.status,
  officer_reviews.decision). This is the human-in-the-loop principle,
  enforced through schema design, not just UI convention.
- The is_current pattern is used for document_extractions and
  compliance_results, where only one row per parent may be current at
  a time, enforced transactionally at the application layer. It is
  deliberately not used for officer_reviews or verification_results,
  which are append-only history with bids.status as the current-state
  pointer for decisions.
- audit_logs is fully immutable: no update, no delete, ever.
