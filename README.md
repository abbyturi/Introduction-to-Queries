# ALY 6420 - Introduction to Querying

This repository contains instructional and technical materials supporting **ALY 6420: Introduction to Querying**. The course develops practical SQL fluency for analytics, beginning with relational data and foundational retrieval and progressing toward data transformation, analytical SQL, complex data types, performance, database programming, and integration with Python.

The repository is intended to support the course learning experience with lecture notebooks, database setup resources, sample data, demonstrations, guided practice, and reproducible technical environments. **Canvas remains the authoritative source for the official course schedule, assignment instructions, due dates, grading requirements, and university policies.**

---

## Course Overview

The course introduces the fundamentals of relational databases, different forms of data, and the use of SQL to retrieve, combine, filter, transform, summarize, and analyze data from multiple sources. The broader course also develops awareness of query efficiency, advanced SQL constructs, complex data types, database programming, and integration between PostgreSQL and analytical programming tools.

The instructional progression emphasizes a **practice-first approach**: learners write SQL early and build increasingly sophisticated solutions as the course advances. Rather than treating SQL as a collection of isolated commands, the course emphasizes the relationship among:

> **business question → data structure → query design → result validation → analytical interpretation**

The course uses realistic datasets and analytical scenarios to develop both SQL syntax and the reasoning required to produce trustworthy results.

---

## Course Learning Objectives

Upon successful completion of the course, students should be able to:

1. **Write data-retrieval queries and evaluate result sets** for correctness and analytical relevance.
2. **Edit data and create database objects** using appropriate SQL Data Manipulation Language (DML) and Data Definition Language (DDL) operations.
3. **Explain the structure and design of relational databases**, including tables, schemas, keys, relationships, constraints, and normalization.
4. **Combine data from multiple sources and tables** using appropriate joins and related query strategies based on the intended result.
5. **Evaluate and improve query performance** using query-planning, indexing, and SQL optimization principles.

Across these objectives, students also practice data cleaning, transformation, aggregation, analytical reasoning, validation, debugging, and communication of query results.

---

## Instructional Approach

The course is organized as a progressive SQL learning sequence. Foundational modules establish relational thinking and precise query construction. Intermediate modules focus on assembling, transforming, and aggregating datasets. Later modules introduce analytical SQL, data movement, complex data types, performance, database programming, case-based problem solving, and programmatic database access.

Lecture materials in this repository are designed to complement the official Northeastern University Canvas materials. They include:

- conceptual explanations and foundational definitions;
- PostgreSQL syntax and annotated examples;
- simple examples before more complex analytical patterns;
- real-world applications;
- guided practice and knowledge checks;
- debugging and common-error discussions;
- query-grain and validation reasoning;
- AI-generated SQL critique exercises where pedagogically appropriate;
- laboratory readiness activities; and
- references for continued study.

---

## Lecture Topics and Course Coverage

The broader course sequence covers the following areas. Repository numbering may evolve as lecture materials are revised; consult Canvas for the official weekly sequence.

| Course Area | Representative Topics |
|---|---|
| **Relational data foundations** | Data and datasets, structured/semi-structured data, relational databases, tables, rows, columns, schemas, primary and foreign keys, relationships, normalization |
| **Foundational SQL querying** | `SELECT`, `FROM`, aliases, expressions, `WHERE`, `ORDER BY`, `LIMIT`, query execution order |
| **Precise filtering and result shaping** | Comparison operators, Boolean logic, `IN`, `BETWEEN`, `LIKE`, `NULL`, output formatting |
| **Database objects and data modification** | DDL and DML, `CREATE`, `ALTER`, `INSERT`, `UPDATE`, `DELETE`, `DROP`, constraints and data types |
| **Combining relational data** | `INNER`, `LEFT`, `RIGHT`, and `FULL OUTER JOIN`; multi-table joins; self-joins; keys, cardinality, fan-out, and grain |
| **Derived datasets and multi-step SQL** | Subqueries, correlated subqueries, `EXISTS`, CTEs, `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT` |
| **Cleaning and transformation** | `CASE`, `COALESCE`, `NULLIF`, `GREATEST`, `LEAST`, string functions, casting, date/time transformations, `DISTINCT` |
| **Aggregation** | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`, conditional aggregation, grouping sets and analytical summaries |
| **Window functions** | `OVER`, `PARTITION BY`, ordering, ranking, running totals, moving calculations, `LAG`, `LEAD`, window frames |
| **Import, export, and intermediate structures** | PostgreSQL `COPY`, psql `\copy`, CSV workflows, validation, temporary tables, views, materialized-view awareness |
| **Complex data types** | JSON, JSONB, arrays, extraction operators, JSON paths, expansion, flattening, `array_agg`, `unnest`, containment and overlap |
| **Text analytics** | Text processing, tokenization, PostgreSQL full-text search, text-search vectors and queries |
| **Query performance** | `EXPLAIN`, `EXPLAIN ANALYZE`, query planning, indexing, execution cost, performance-oriented SQL design |
| **Database programming** | User-defined functions, procedural database logic, triggers and automated database behavior |
| **Applied SQL case studies** | Multi-step analytical problems, business-oriented query design, validation and interpretation |
| **Python/database integration** | Python, pandas, PostgreSQL connectivity, SQLAlchemy/DBAPI-style workflows, moving query results into analytical code |
| **Course synthesis** | Integrating relational reasoning, query construction, performance, validation, and analytical communication |

---

## Practice Databases

### Pagila

**Pagila** is the primary relational practice database included with the repository. It is a PostgreSQL adaptation of the well-known DVD rental sample database and provides interconnected entities such as customers, films, inventory, rentals, payments, stores, staff, actors, and categories.

Pagila is useful because the same schema can support increasingly sophisticated questions-from a first `SELECT` statement to joins, aggregation, subqueries, CTEs, window functions, and performance analysis.

The repository contains Pagila schema/data scripts under:

```text
data/pagila/
```

### ZoomZoom / `sqlda`

Later course materials may use the **ZoomZoom (`sqlda`)** dataset for applied analytical examples, data import/export, and complex-data exercises. When used, students should follow the corresponding Canvas/module instructions for obtaining and loading the dataset.

---

## Technical Environment

The official course workflow uses a PostgreSQL-centered analytics environment.

### Core tools

| Tool | Purpose |
|---|---|
| **PostgreSQL 16** | Relational database engine used to execute SQL |
| **Neon** | Cloud-hosted PostgreSQL environment used in the course |
| **DBeaver Community Edition** | Primary graphical SQL client for connecting to PostgreSQL and writing/running queries |
| **Python 3.x** | Used in later modules for programmatic database integration |
| **Jupyter / IPython** | Supports lecture notebooks and reproducible demonstrations in this repository |
| **pandas** | Used to work with query results in Python |
| **SQLAlchemy / psycopg2** | PostgreSQL connectivity from Python |
| **Git** | Recommended for cloning the repository and tracking local work |

A local PostgreSQL installation is not required when using the official Neon workflow.

---

## Installation and Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd Introduction-to-Queries
```

Alternatively, download the repository as a ZIP file and extract it locally.

### 2. Create the supplied Conda environment

The repository includes:

```text
introqueriesenv.yml
```

Create the environment:

```bash
conda env create -f introqueriesenv.yml
```

Activate it:

```bash
conda activate introqueries
```

The environment is currently lightweight and includes only Python, Jupyter kernel support, pandas, SQLAlchemy, psycopg2, and `ipython-sql`.

### 3. Register the Jupyter kernel if needed

```bash
python -m ipykernel install --user \
  --name introqueries \
  --display-name "Python (introqueries)"
```

### 4. Install DBeaver

Install **DBeaver Community Edition** and use it as the primary SQL client for the course.

### 5. Configure PostgreSQL / Neon

Create or use the PostgreSQL instance specified in the course setup instructions. In DBeaver, configure a PostgreSQL connection using the host, database, username, password, port, and SSL information supplied by your database environment.

**Do not commit database passwords, connection strings, `.env` files, or credentials to this repository.**

### 6. Load the practice database

The Pagila assets are located in:

```text
data/pagila/
```

The introductory setup notebook is:

```text
labs/lab0_postgreSQL_env_setup.ipynb
```

Follow the setup material and official Canvas instructions for the current course environment.

### 7. Open the lecture notebooks

From the activated environment:

```bash
jupyter lab
```

or:

```bash
jupyter notebook
```

Then open the relevant notebook from:

```text
lectures/
```

Most lecture notebooks emphasize explanatory Markdown and SQL examples; SQL execution is generally performed against the configured PostgreSQL environment.

---

## Repository Structure

The current repository is organized broadly as follows:

```text
Introduction-to-Queries/
│
├── README.md
├── introqueriesenv.yml
│
├── data/
│   └── pagila/
│       ├── pagila-schema.sql
│       ├── pagila-data.sql
│       ├── pagila-insert-data.sql
│       ├── pagila-schema-jsonb.sql
│       ├── pagila-schema-diagram.png
│       ├── Dockerfile
│       ├── docker-compose.yml
│       └── additional Pagila setup assets
│
├── labs/
│   
│
└── lectures/
    ├── module01_overview.ipynb
    ├── module01_lecture.ipynb
    ├── module02_lecture.ipynb
    ├── module04_lecture.ipynb
    ├── module05_lecture.ipynb
    ├── module06_lecture.ipynb
    ├── module07_lecture.ipynb
    ├── module08_lecture.ipynb
    ├── module09_lecture.ipynb
    └── module10_lecture.ipynb
```

The repository is expected to evolve as additional lecture, troubleshooting notes, lab, data, and supporting resources are added. 

---

## Query-Validation Principles

Throughout the course, use the following questions when evaluating SQL:

- **What is the analytical question?**
- **What should one row of the result represent?**
- **Which table or derived dataset establishes that grain?**
- **Which keys connect the required entities?**
- **Could a join multiply rows?**
- **How should missing values be treated?**
- **Are filters applied at the correct stage?**
- **Are extracted or transformed values using the correct SQL data type?**
- **Does aggregation preserve the intended denominator?**
- **Are the results plausible when checked against counts, ranges, or sample records?**
- **Can the query be simplified or made more efficient without changing its meaning?**

These habits are central to writing analytical SQL that is not merely syntactically valid, but trustworthy.

---

## AI Disclaimer

AI tools may have been used in a limited editorial and research-support capacity to **synthesize, organize, cross-reference, and format relevant instructional resources and documentation** during compilation of these repository materials. AI assistance should not be interpreted as the source or authority for the course content. Technical claims, examples, and references should be evaluated against the assigned textbook, official PostgreSQL documentation, course materials, and instructor review.

*Note* 
The repository's AI-compilation disclaimer is separate from student AI-use requirements.

For coursework and assessments, students must follow the **AI-use designation provided in the syllabus and for each assignment**. Where AI use is permitted, students remain responsible for verifying SQL, interpreting results, disclosing use when required, protecting confidential information, and complying with the University's academic-integrity expectations.

---

## Primary Reference

> Shan, J., Li, H., Goldwasser, M., Malik, U., & Johnston, B. (2025). *SQL for Data Analytics: Analyze Data Effectively, Uncover Insights and Master Advanced SQL for Real-World Applications* (4th ed.). Packt Publishing.

Consult the current Canvas module for the required chapter and edition.

---

## Additional Resources

The following resources are useful companions to the course:

### PostgreSQL documentation

- **PostgreSQL Documentation** - authoritative reference for SQL syntax, data types, functions, joins, CTEs, JSON/JSONB, arrays, window functions, indexing, `COPY`, `EXPLAIN`, and database programming.
- **PostgreSQL Tutorial** - useful for foundational relational and SQL concepts.
- **psql documentation** - particularly useful for client-side operations such as `\copy`.

### Course technology

- **Neon documentation** - PostgreSQL connection, cloud database management, connection strings, and operational guidance.
- **DBeaver documentation** - connection setup, SQL editor usage, import/export, metadata browsing, and result-set tools.
- **Jupyter documentation** - notebook and kernel management.
- **pandas documentation** - working with tabular query results in Python.
- **SQLAlchemy documentation** - database connectivity and SQL integration from Python.
- **psycopg documentation** - PostgreSQL access from Python.

### SQL practice

- **PostgreSQL Exercises** - focused practice with joins, aggregation, subqueries, date/time operations, and related PostgreSQL skills.
- **Pagila sample database** - the repository's primary relational practice environment.

---

## Reference List

PostgreSQL Global Development Group. (n.d.). *PostgreSQL documentation*.

Shan, J., Goldwasser, M., & Malik, U. (2022). *SQL for data analytics: Harness the power of SQL to extract insights from data* (3rd ed.). Packt Publishing.

Shan, J., Li, H., Goldwasser, M., Malik, U., & Johnston, B. (2025). *SQL for data analytics: Analyze data effectively, uncover insights and master advanced SQL for real-world applications* (4th ed.). Packt Publishing.

Northeastern University College of Professional Studies. (2026). *ALY 6420: Introduction to Querying - Canvas instructional materials*.

Additional technical references include the official documentation for Neon, DBeaver, Jupyter, pandas, SQLAlchemy, and PostgreSQL Python connectivity libraries.

---

## Course Materials and Attribution

This repository supports **ALY 6420: Introduction to Querying** at Northeastern University.

*Credit is extended to the Northeastern University instructional team of instructors and the lead Instructor Prof. Joe Reilly, who developed and composed the ALY 6420 Canvas course materials. Their course design, learning objectives, instructional sequencing, activities, assessments, and supporting materials provide the academic framework within which these repository resources are organized.*

The lecture materials in this repository have been compiled and organized to align with the course syllabus, Canvas learning objectives, assigned readings, PostgreSQL documentation, and supporting instructional resources. They are intended to complement-not replace-the official Canvas course materials.

---

**Instructor: Abeba N. Turi (Ph.D.)*  
*Northeastern University | College of Professional Studies*
