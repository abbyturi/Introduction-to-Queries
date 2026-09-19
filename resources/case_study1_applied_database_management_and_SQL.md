# Applied Database Management and SQL

## A Multi-User Application Case Study

### Lecture Note and Student Reference

## 1. From SQL Queries to a Multi-User Database System

Learning SQL involves more than knowing how to write `SELECT`, `INSERT`, `UPDATE`, and `DELETE` statements. In a real application, SQL operates within a larger system involving users, application logic, authentication, deployment environments, and persistent storage. A query can be syntactically correct while still producing the wrong result because the wrong database, relationship, record, or application state was used.

Consider a generic application in which users create records that must be reviewed. The records could represent project submissions, documents, requests, academic work, operational records, or other items.

A typical lifecycle is:

```text
Create → Draft → Submit → Pending Review
                              |
                   +----------+----------+
                   |          |          |
                Approve     Revise     Reject
                              |
                              v
                         User edits
                              |
                           Resubmit
                              |
                              v
                         Review again
```

This simple workflow introduces several database-management questions. What uniquely identifies a record? Who owns it? What is its current status? How should previous reviews be preserved? What happens when two users change the same record? How should a local development application interact with a cloud pilot database?

These questions connect directly with the relational foundations, DML, joins, aggregation, JSONB, query validation, performance, and Python/PostgreSQL integration covered throughout the **Introduction to Queries** course.

### Grain and record identity

Before writing SQL, determine the **grain** of the data:

> What does one row represent?

For the main application table:

```text
one row = one workflow record
```

For a review-history table:

```text
one row = one review event
```

This distinction becomes especially important when tables are joined. It is also why relational design begins with entities, keys, relationships, and constraints rather than immediately writing queries.

A simplified main table might be:

```sql
CREATE TABLE workflow_records (
    record_id TEXT PRIMARY KEY,
    owner_id TEXT NOT NULL,
    title TEXT NOT NULL,
    status TEXT NOT NULL,
    submission_version INTEGER NOT NULL DEFAULT 0,
    submitted_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

The `PRIMARY KEY` gives every record a stable identity. `NOT NULL` prevents required attributes from being omitted, while appropriate data types give the DBMS information about what each value represents.

The application may also restrict valid workflow states:

```sql
ALTER TABLE workflow_records
ADD CONSTRAINT valid_status
CHECK (
    status IN (
        'Draft',
        'Pending Review',
        'Needs Revision',
        'Approved',
        'Rejected'
    )
);
```

This illustrates an important distinction between **application logic** and **database integrity**. The application determines when a user should be allowed to approve or revise something. The database can independently ensure that impossible status values are not stored.

---

## 2. CRUD, Review History, and Relational Queries

Most user actions in a database-backed application eventually become CRUD operations.

| User action               | CRUD operation | SQL      |
| ------------------------- | -------------- | -------- |
| Create a record           | Create         | `INSERT` |
| Display records           | Read           | `SELECT` |
| Edit or change status     | Update         | `UPDATE` |
| Remove an eligible record | Delete         | `DELETE` |

Creating a draft might use:

```sql
INSERT INTO workflow_records
    (record_id, owner_id, title, status)
VALUES
    ('R1001', 'user_101', 'Example Record', 'Draft');
```

Retrieving only the records belonging to a particular user might use:

```sql
SELECT record_id, title, status, updated_at
FROM workflow_records
WHERE owner_id = 'user_101'
ORDER BY updated_at DESC;
```

The `WHERE` clause is particularly important for DML. For example:

```sql
UPDATE workflow_records
SET title = 'Updated Record'
WHERE record_id = 'R1001';
```

targets one record, while omitting `WHERE` could update the entire table. A useful development practice is therefore to test the intended predicate with `SELECT` before performing an important `UPDATE` or `DELETE`.

### Preserving the review history

Current status and historical activity are different concepts. Suppose a record follows:

```text
Version 1 → Needs Revision
Version 2 → Needs Revision
Version 3 → Approved
```

The main table may correctly contain:

```text
R1001 | Approved
```

but this does not explain how the record reached that state.

One relational solution is a second table:

```sql
CREATE TABLE record_reviews (
    review_id BIGSERIAL PRIMARY KEY,
    record_id TEXT NOT NULL,
    submission_version INTEGER NOT NULL,
    decision TEXT NOT NULL,
    reviewer_id TEXT NOT NULL,
    reviewed_at TIMESTAMPTZ NOT NULL,
    comments TEXT,
    FOREIGN KEY (record_id)
        REFERENCES workflow_records(record_id)
);
```

The relationship is:

```text
workflow_records  1 ─────── *  record_reviews
```

One record can therefore have many reviews.

This supports a query such as:

```sql
SELECT
    r.record_id,
    r.status AS current_status,
    rv.submission_version,
    rv.decision,
    rv.reviewed_at
FROM workflow_records r
LEFT JOIN record_reviews rv
    ON r.record_id = rv.record_id
ORDER BY r.record_id, rv.reviewed_at;
```

Students should notice that the grain changes after the join. A record with three reviews now appears three times. If a numeric value from the main record were summed after this join, it could be counted three times. This is **join fan-out**, and it demonstrates why understanding keys, cardinality, and grain is as important as knowing JOIN syntax.

PostgreSQL `JSONB`, another topic in the course, can alternatively store flexible history or metadata. JSONB is useful when the structure is variable, while a normalized table is generally easier when review events need relational constraints, joins, and regular analytical queries. Neither approach is universally correct; the choice depends on how the data will be managed and queried.

---

## 3. From Local Development to a Shared Pilot Database

An application often begins with local file storage such as JSON:

```text
Local Application → JSON File
```

This can work well during early development because it is simple and easy to inspect. The limitations become clearer when several users need to modify shared information.

Suppose two application processes read the same JSON collection. User A changes one record and saves it. User B, still holding an older copy, changes another record and rewrites the collection. Depending on the implementation, B may unintentionally overwrite A's newer change.

A DBMS such as PostgreSQL provides facilities specifically designed for shared persistence, including primary keys, transactions, concurrent connections, constraints, row-level operations, indexes, and locking mechanisms.

### A common pilot architecture problem

Suppose development continues locally using JSON while a deployed pilot uses PostgreSQL:

```text
LOCAL                         PILOT

Application                   Application
    |                             |
    v                             v
Local JSON                   PostgreSQL
```

A pilot user creates a record, but the developer cannot see it locally.

This is not necessarily a synchronization failure. The two applications simply have **different sources of data**.

The important architectural question is:

> Which data store is the source of truth?

If both stores independently hold authoritative copies, a synchronization mechanism is required. That introduces conflict detection, deletion handling, retry logic, version comparison, and rules determining which copy wins when both change.

For a controlled pilot, a simpler arrangement can be:

```text
                Test PostgreSQL
                 /            \
                /              \
               v                v
       Local Application    Pilot Application
```

Both applications use the same authoritative **test database**.

This is **shared persistence**, not synchronization:

```text
Two databases + copying = synchronization

Two applications + one database = shared persistence
```

This distinction is important because unnecessary synchronization can create a much more complicated system.

### Environment separation

A shared test database does not mean development should normally connect directly to live production data. Mature systems generally separate:

```text
Development → Development DB
Testing     → Test DB
Staging     → Staging DB
Production  → Production DB
```

A controlled pilot may intentionally share a test database with local development, but production should normally remain isolated from development experiments.

Applications commonly determine the database through configuration such as:

```text
DATABASE_URL
```

Persistent Database Configuration Across Development Sessions

Shared persistence also depends on the application consistently receiving the correct database configuration when it starts.

A developer may temporarily configure a database connection in a terminal:

export DATABASE_URL='<database-connection-url>'

This works for the current shell session, but the setting may disappear when the terminal is closed. If the application has a local fallback data source, a later session may then display different records even though the database itself is functioning correctly.

The situation can be represented as:

Session 1
Local Application ──→ Shared Test Database ←── Pilot Application
                         Same records

Session 2
Local Application ──→ Local fallback
Pilot Application ──→ Shared Test Database
                         Different records

This is a configuration problem rather than a synchronization problem. The applications are no longer using the same source of truth.

For persistent development, database configuration should be loaded through an appropriate environment-management mechanism when a new development session starts. Credentials should remain outside source code and should never be committed to Git.

A useful diagnostic is to verify configuration:

import os

print(bool(os.getenv("DATABASE_URL")))

The connection itself should also be tested independently before debugging application logic.

The general troubleshooting sequence is:

Records differ
    ↓
Check database configuration
    ↓
Check Python/runtime environment
    ↓
Test database connection
    ↓
Confirm both applications use the same database
    ↓
Then investigate application logic

The key lesson is:

Two applications remain consistent only when they continue to use the same authoritative data source. Persistent configuration is therefore part of reliable database application design.

---

## 4. Multi-User Concurrency and Transactions

Moving to PostgreSQL does not automatically eliminate every multi-user problem. Application logic must still account for **concurrency**.

Suppose Reviewer A and Reviewer B both open `R1001` while its state is:

```text
Pending Review
```

Reviewer A approves it. Reviewer B's screen still contains the older state and requests revision.

A naive operation is:

```sql
UPDATE workflow_records
SET status = 'Needs Revision'
WHERE record_id = 'R1001';
```

This can overwrite the approval.

A stronger operation is:

```sql
UPDATE workflow_records
SET
    status = 'Needs Revision',
    updated_at = CURRENT_TIMESTAMP
WHERE record_id = 'R1001'
  AND status = 'Pending Review';
```

This means:

> Request revision only if the record is still waiting for review.

If Reviewer A already changed the record, PostgreSQL updates zero rows. The application can interpret this as a concurrency conflict and require Reviewer B to reload the latest state.

A more general optimistic-concurrency design uses a version column:

```sql
row_version INTEGER NOT NULL DEFAULT 1
```

The application might read version `7` and later attempt:

```sql
UPDATE workflow_records
SET
    status = 'Approved',
    row_version = row_version + 1
WHERE record_id = 'R1001'
  AND row_version = 7;
```

If another user has already changed the record and the database now contains version `8`, zero rows are updated. This prevents a stale application copy from silently overwriting newer data.

### Transactions

Some user actions require several related database changes. Approving a record might require updating the current status and inserting a review-history record.

These should usually behave as one logical operation:

```sql
BEGIN;

UPDATE workflow_records
SET
    status = 'Approved',
    reviewed_at = CURRENT_TIMESTAMP,
    approved_at = CURRENT_TIMESTAMP
WHERE record_id = 'R1001'
  AND status = 'Pending Review';

INSERT INTO record_reviews (
    record_id,
    submission_version,
    decision,
    reviewer_id,
    reviewed_at
)
VALUES (
    'R1001',
    3,
    'Approved',
    'reviewer_01',
    CURRENT_TIMESTAMP
);

COMMIT;
```

If part of the operation fails, the transaction can be rolled back.

The desired behavior is:

```text
All related changes succeed → COMMIT

Something fails → ROLLBACK
```

rather than leaving the database in a partially updated state.

This is one reason databases are more than storage containers. They help maintain reliable state while several users and operations interact.

---

## 5. Migration, Validation, Performance, and System Diagnosis

When a prototype moves from local JSON to PostgreSQL, existing records may need a one-time migration:

```text
Local Data
    |
    v
Backup
    |
    v
Migration
    |
    v
PostgreSQL
    |
    v
Validation
```

Suppose PostgreSQL already contains `R1001`, `R1002`, and `R1003`, while the local source contains `R1003`, `R1004`, and `R1005`.

The duplicate `R1003` creates a decision:

> Which version is authoritative?

The primary key can identify the conflict, but SQL cannot independently decide the business meaning of that conflict.

PostgreSQL supports UPSERT:

```sql
INSERT INTO workflow_records (
    record_id, owner_id, title, status
)
VALUES (
    'R1001', 'user_101', 'Example', 'Draft'
)
ON CONFLICT (record_id)
DO UPDATE SET
    title = EXCLUDED.title,
    status = EXCLUDED.status;
```

However, an UPSERT is a technical mechanism, not a conflict-resolution policy. The team must still determine whether overwriting existing data is appropriate.

### Validate the migration

A successful script execution does not prove that the migrated data is correct.

Useful checks include:

```sql
SELECT COUNT(*)
FROM workflow_records;
```

and:

```sql
SELECT status, COUNT(*)
FROM workflow_records
GROUP BY status;
```

as well as:

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT record_id) AS unique_records
FROM workflow_records;
```

These queries can reveal unexpected counts, duplicate identities, or missing categories.

SQL can also test business rules. For example:

```sql
SELECT *
FROM workflow_records
WHERE status = 'Approved'
  AND approved_at IS NULL;
```

If every approval must have a timestamp, the expected result is zero rows.

This illustrates an important course theme: **validation is part of querying**. A query result should be tested against the expected grain, relationships, counts, and business meaning.

### Performance

As the database grows, access patterns become important.

If reviewers frequently search for pending records:

```sql
SELECT *
FROM workflow_records
WHERE status = 'Pending Review';
```

an index may be useful:

```sql
CREATE INDEX idx_workflow_status
ON workflow_records(status);
```

Students can then investigate the execution plan:

```sql
EXPLAIN ANALYZE
SELECT *
FROM workflow_records
WHERE status = 'Pending Review';
```

This connects directly with the course material on indexing, `EXPLAIN`, `EXPLAIN ANALYZE`, query plans, and performance.

Indexes should not simply be added everywhere. They consume storage and create additional work during `INSERT`, `UPDATE`, and `DELETE`. Performance decisions should therefore be supported by actual query patterns and execution evidence.

### Diagnosing the complete system

Finally, not every apparent database problem originates in SQL.

A multi-user application may involve:

```text
User
 |
 v
Authentication
 |
 v
Authorization
 |
 v
Application Logic
 |
 v
Data-Access Layer
 |
 v
SQL
 |
 v
PostgreSQL
 |
 v
Application Read
 |
 v
User Interface
```

Suppose the interface says a record is Approved when the user expected Needs Revision. Instead of immediately modifying code, query PostgreSQL:

```sql
SELECT
    record_id,
    status,
    reviewed_at,
    approved_at
FROM workflow_records
WHERE record_id = 'R1001';
```

If PostgreSQL says `Needs Revision`, the database write may be correct and the problem may exist in application state, caching, querying, or rendering.

If PostgreSQL says `Approved`, investigation should move toward the application action and SQL write.

This leads to a useful diagnostic sequence:

```text
1. What should have happened?
2. What is the record's primary key?
3. What does PostgreSQL actually contain?
4. Is the application connected to the correct database?
5. What SQL operation occurred?
6. How many rows were affected?
7. Could another user have changed the record?
8. Did the application reload the persisted state?
9. Is the deployed code the expected version?
10. Can the result be independently verified with SQL?
```

## Conclusion

This case connects introductory SQL concepts to the practical operation of a multi-user application.

The progression is:

```text
Local prototype
      |
      v
Relational database
      |
      v
Multi-user CRUD
      |
      v
Review workflow
      |
      v
History + JOINs
      |
      v
Concurrency + Transactions
      |
      v
Shared pilot database
      |
      v
Migration + Validation
      |
      v
Performance + Diagnosis
```

The central lesson is that reliable database work requires more than asking:

> **Does this SQL statement run?**

Students should also ask:

> What does one row represent? What is the primary key? What is the source of truth? Could this JOIN multiply rows? Could another user modify the record concurrently? Is this operation transactional? Am I connected to the correct database? Is this synchronization or shared persistence? How can I independently validate the result?

These questions connect the relational foundations, DML, joins, aggregation, JSONB, transactions, performance, and Python/PostgreSQL concepts in the **Introduction to Queries** course to the way databases function inside real multi-user applications.
