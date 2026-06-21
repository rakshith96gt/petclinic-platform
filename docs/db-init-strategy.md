# Database Initialization Strategy — Petclinic Platform

**Last Updated:** 2026-06-21
**Purpose:** Document the schema initialization strategy for the shared MySQL database.

## Overview

All three domain services (Customers, Visits, Vets) share a single MySQL database named `petclinic`. This design is chosen to support foreign key constraints across services (specifically `visits.pet_id` → `pets.id`) while keeping operational complexity and cost low.

## Initialization Strategy

We use **Spring Boot Auto-Initialization** via the `spring.sql.init` properties.

### Mechanism
Each service includes a `schema.sql` file in `src/main/resources/db/mysql/`. When the service starts with the `mysql` profile, Spring Boot executes these scripts.

**Configuration:**
- `spring.sql.init.mode=always`
- `spring.datasource.url=jdbc:mysql://{rds-endpoint}:3306/petclinic`

### Initialization Order
Due to foreign key dependencies, services must be initialized (or deployed) in the following order:

1. **Customers Service**: Creates `types`, `owners`, and `pets` tables.
2. **Vets Service**: Creates `vets`, `specialties`, and `vet_specialties` tables. (Independent)
3. **Visits Service**: Creates `visits` table (depends on `pets` from Customers Service).

This order is enforced in Kubernetes using init containers that wait for the dependency services to be healthy, and by the deployment sequence in the CI/CD pipeline.

## Database Schema Details

| Service | Tables Created | Dependencies |
|----------|----------------|--------------|
| Customers | `types`, `owners`, `pets` | None |
| Vets | `vets`, `specialties`, `vet_specialties` | None |
| Visits | `visits` | `pets` (Customers Service) |

## Connection Configuration

For Kubernetes ConfigMaps and environment variables, the following format is used:

**JDBC URL:**
`jdbc:mysql://petclinic-{env}-mysql.xxxxxx.ap-south-2.rds.amazonaws.com:3306/petclinic`

**Credentials:**
Sourced via External Secrets Operator (ESO) from AWS Secrets Manager:
- Secret: `petclinic/{env}/rds-credentials`
- Keys: `username`, `password`
