# PRAMAAN

**AI-Powered Integrated Bid Compliance Verification Platform for GeM Procurement**

Smart India Hackathon — Problem Statement SIH26100
Domain: Smart Automation / Government Procurement

---

## 1. Overview

PRAMAAN is an AI-assisted compliance verification and decision-support
platform for GeM (Government e-Marketplace) procurement. It helps
procurement officers verify bidder statutory and eligibility documents
(GST, PAN, Udyam/MSME, EPFO/ESIC, and others) faster and more
consistently, using OCR-based extraction, cross-document validation, and
a configurable, data-driven compliance rule engine.

## 2. Problem Statement

Manually verifying bidder compliance documents is slow, repetitive,
inconsistent between reviewers, and difficult to audit at scale. As GeM
tender volume grows, this manual process becomes a bottleneck and a
source of avoidable procurement risk.

## 3. Proposed Solution

PRAMAAN automates the mechanical parts of document verification —
extraction, format validation, cross-document consistency checks, and
rule-based scoring — while leaving the final qualify/disqualify decision
with the authorized Procurement Officer.

## 4. Key Capabilities

- Secure document upload and storage
- OCR-based field extraction with confidence scoring
- Configurable, data-driven compliance rule engine (no redeploy needed
  to add or change a rule)
- Cross-document consistency checks (e.g. name/PAN/address matching)
- Weighted compliance scoring and risk classification
- Officer review workflow with mandatory-reason overrides
- Immutable audit trail
- Final compliance report visible to both officer and bidder

## 5. User Roles

| Role | Responsibilities |
|---|---|
| Bidder | Registers, creates bids, uploads documents, views AI assessment and final officer decision |
| Officer | Reviews bids, AI findings, and evidence; makes the final procurement decision; can override AI assessment with a mandatory reason |
| Admin | Manages users, compliance rules, and system configuration |

## 6. High-Level Architecture

    React (public site + authenticated app)
            |  HTTPS / REST (JWT)
            v
    Spring Boot (Java 21) - auth, RBAC, bids, documents,
    rule engine, compliance evaluation, officer workflow, audit
            |  server-to-server, multipart
            v
    FastAPI AI Service - OCR / structured document extraction
    (stateless, no direct database access)

    Government Verification Adapters - interface layer,
    MOCK implementations initially, swappable for authorized
    live integrations later

    MySQL - single database for all business and audit data

A modular monolith (Spring Boot) plus one separate AI/OCR service —
not a full microservices architecture — to keep operational complexity
proportional to the project's actual scale.

## 7. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | React, Vite |
| Backend | Java 21, Spring Boot, Maven, Spring Security, JWT, JPA/Hibernate |
| AI Service | Python, FastAPI, Tesseract OCR |
| Database | MySQL 8 |
| Infrastructure | Docker, GitHub Actions (CI/CD), Vercel (frontend), Render or equivalent (backend/AI), Aiven or equivalent (managed MySQL) |

## 8. Project Structure

    pramaan/
    |-- README.md
    |-- LICENSE
    |-- .gitignore
    |-- .env.example
    |-- docker-compose.yml
    |-- docs/
    |   |-- architecture/
    |   |-- database/
    |   |-- api/
    |   |-- security/
    |   |-- deployment/
    |   `-- demo/
    |-- frontend/
    |-- backend/
    |-- ai-service/
    |-- tests/
    `-- scripts/

## 9. Development Status

This repository is being built incrementally, in phases, with meaningful
commits at each step. Current status: project foundation (repository
structure, tooling skeletons). Business features have not yet been
implemented.

A separate, earlier prototype validated the end-to-end business
workflow; this repository is a clean, production-oriented rebuild, not
a copy of that prototype.

## 10. Security Principles

- Passwords hashed (BCrypt), never stored or logged in plain text
- JWT-based authentication, role-based access control (RBAC)
- No secrets committed to source control; .env.example files provide
  placeholders only
- Input and file upload validation
- Immutable, append-only audit logging
- Environment-based configuration for all deployment targets

## 11. AI + Human-in-the-Loop Principle

PRAMAAN provides AI-assisted compliance verification and decision
support. Final procurement decisions remain with the authorized
Procurement Officer. The AI-generated assessment (score, risk level,
findings) and the officer's final decision are always displayed and
stored as distinct, separately identifiable pieces of information.

## 12. Verification Integration Strategy

Government verification (GST, PAN, Udyam, EPFO/ESIC, and similar) is
implemented behind provider interfaces. During development, all
providers are mock/simulated implementations; no live government API
access exists. The system clearly labels verification results as either:

- Simulated verification (current state), or
- Authorized live verification (future state, pending real
  integration agreements)

No real government API credentials are ever hardcoded or committed to
this repository.

## 13. Local Development

Setup instructions for each module (frontend, backend, ai-service) will
be added here as those modules are scaffolded in upcoming steps.

## 14. Testing

A testing strategy (unit, integration, and end-to-end) will be
documented here as test suites are introduced in later phases.

## 15. Deployment

Deployment instructions and environment variable requirements will be
documented here once a deployable version exists.

## 16. Disclaimer

PRAMAAN is developed as part of Smart India Hackathon submission
SIH26100. It does not currently integrate with any live government
verification system. All verification shown during development is
simulated for demonstration purposes only.
