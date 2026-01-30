
---

# Divide & Conquer: PostgreSQL Partitioning


This guide covers the internal mechanics of PostgreSQL partitioning and the trade-offs involved in scaling large databases.

---
### Navigation:

- [Theory](#1-the-scaling-wall)
- [Practice](#practice)
- [Deeper Dig](#dig-deeper)

---

## 1. The Scaling Wall

As a table grows (typically >100GB), standard SQL performance degrades due to physical and mathematical constraints:

- **Index Depth:** B-tree indexes become too deep. Every lookup requires more **Random I/O** to reach the leaf nodes.
- **Table Bloat:** Vacuuming massive tables becomes inefficient. "Dead tuples" accumulate faster than the `VACUUM` can clean them.
- **Maintenance Overhead:** Operations like `ALTER TABLE` or `CREATE INDEX` lock the entire table for hours, causing downtime.

---

## 2. Evolution: Declarative Partitioning

PostgreSQL moved from "hacked" inheritance to native, high-performance partitioning:

* **Legacy (Inheritance):** Relied on manual triggers. Every row insertion was interpreted by PL/pgSQL, which was slow.
* **Modern (Declarative):** Uses **Tuple Routing** at the C-kernel level. Rules (`RANGE`, `LIST`, `HASH`) are declared, and the engine handles routing automatically.

---
## 3. Partitioning Strategies

- **Range:** Each partition is a range of values. Basically used for timeseries data (date, timestamp).
- **List:** Each partition is a list of values. Typically used with geo areas or tenants
- **Hash:** Each partition is a hash of the value. Distributes data evenly across partitions, **BUT [partition pruning](#5-partition-pruning) is not possible**.
---

## 4. Under the Hood

When you create a partitioned table, Postgres treats it as a logical hierarchy:

1. **Parent Table:** A "virtual" object. It has no physical heap file (no data on disk, always 0 byte file).
2. **pg_partitioned_table:** A system catalog that stores the partitioning strategy and keys. Other related data is kept in **pg_class** and **pg_inherits**.
3. **Tuple Routing:** A low-latency algorithm that calculates which child table (partition) should receive the data.

---
## 5. Partition Pruning

Pruning is what makes partitioning fast by excluding irrelevant tables from the execution plan:

* **Static Pruning:** Happens during query planning.
* **Dynamic Pruning (Starting from Postgres 11):** Happens at runtime (e.g., when the filter value comes from a subquery or a JOIN).
* **The Result:** If you query for "February," Postgres never even opens the file handles for "March" or "April."

---

## 6. Other Advantages of Partitioning

| Feature                          | Description                                                                                                                                                                             |
|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Saving B-Trees**               | By splitting one giant index into 10 small ones, we ensure the "active" indexes fit entirely in **Shared Buffers** (RAM), avoiding disk latency.                                        |
| **Cold Storage**                 | Moving old partitioned tables for timeseries to cheap HDD storage and keep SDD drives with 'hot data'                                                                                   |
| **Maintaince**                   | Faster `VACUUM` and autovacuuming, faster `REINDEX` on lower tables                                                                                                                     |
| **Recovery Time Objective**      | Restoring data from backup-ed table for a last month is a way faster than restoring all historical data                                                                                 |
| **Parallel Scans for Aggregation** | Postgres Engine launches several workers to scan several partitions simultaniously to speed-up aggregating function                                                                     |
| **Transaction ID Wraparound**    | Postgres has limited amount of Transaction IDs so it can be exhausted causing data loss or corruption. `VACUUM` helps here which is better run on smaller tables than one enormous one. |

---

## 7. Day 2 Operations

Partitioning is an operational superpower:

* **DROP vs. DELETE:** Deleting a million rows generates massive WAL logs. Dropping a partition (`DROP TABLE`) is a filesystem-level operation—instant and clean.
* **DETACH:** `DETACH PARTITION` removes it from relation to parent table, so data cannot be accessed via parent table, but keeps it physically so it's possible to back it up or get data via direct reference.
---

## 8. The "Scatter-Gather" Problem and Other Pitfalls

1. **Scatter-Gather:** If a query lacks the partition key in the `WHERE` clause, the planner is forced to scan **every** partition. This causes an I/O storm, especially on slow external disks.
2. **The Unique Trap:** `UNIQUE` and `PRIMARY KEY` constraints **must** include the partition key. Postgres cannot globally enforce uniqueness across different physical files efficiently.
3. **Lock Contention:** Attaching of a new partition via `ATTACH PARTITION` requires `ACCESS EXCLUSIVE` on parent table, which blocks it for the duration of the operation from all queries (even `SELECT`). So partitions must be created and attached beforehand.
4. **Over-partitioning:** slows down Query Planner and can lead to exhausting of file descriptors on OS level (`ulimit`).
5. **Row movement:** Postgres automatically moves rows between partitions based on a partitioning key, but it leads to blocking of two tables, so it's an expensive operation.

## 9. Partitioning in Other RDBMS

|                                  | PostgreSQL                                                             | Oracle                                                                                                                                                                                                                     | MySQL                                    | MS SQL Server                                                                                                                                                                  |
|----------------------------------|------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Partition organization**       | Each partition is a separate table, so it has a **separate HEAP file** | - **Tablespaces:** Each partition can mapped to different tablespaces and mapped to different disk storage (LUNs)<br/>- **Extents**: Data is stored here. Partitions can have different parameters, e.g. compression rate. | Each partition is a separate `.idb` file | You create **Partition Function** (how to split data) and **Partition Scheme** (where to place data) and apply it to table. Then you can reuse them for different other tables |
| **Global indexes**               | Absent (but are likely to appear in future)                            | Present                                                                                                                                                                                                                    | Absent                                   | Present                                                                                                                                                                        |
| **Partition Creation** | Manual                                                                 | Automatic (Interval Partitioning)                                                                                                                                                                                          | Manual                                   | Manual                                                                                                                                                                         |

---
# Practice

---
# Dig Deeper
A section where you can find sources for spreading your knowledge related to PostgreSQL scaling.
- [How PostgreSQL processes queries and how to analyze them](https://aws.amazon.com/blogs/database/how-postgresql-processes-queries-and-how-to-analyze-them/)
- [Navigating Database Deadlocks in High-Concurrency Web Applications](https://leapcell.io/blog/navigating-database-deadlocks-in-high-concurrency-web-applications)
- [PostgreSQL Performance Optimization: What Actually Matters](https://www.bairesdev.com/blog/postgresql-performance-optimization/)
- [Scaling the GitLab database](https://about.gitlab.com/blog/scaling-the-gitlab-database/)
- [Five PostgreSQL Anti-Patterns](https://shey.ca/2025/09/12/five-db-anti-patterns.html)
- [Why we need VACUUM to implement MVCC In PostgreSQL](https://www.enterprisedb.com/postgres-tutorials/why-we-need-vacuum-implement-mvcc-postgresql)
- [MVCC (Multi-Version Concurrency Control)](https://www.postgresql.org/docs/7.1/mvcc.html)
- [GitLab scalability](https://docs.gitlab.com/development/scalability/)
- [Postgres Performance Issues and How to Scale Enterprise Databases](https://www.singlestore.com/blog/postgres-performance-issues-and-how-to-scale-enterprise-databases/)
- [The Core of PostgreSQL: Understanding Transactions, Isolation, and MVCC](https://medium.com/@rahulhind/the-core-of-postgresql-understanding-transactions-isolation-and-mvcc-90247992f14e)
