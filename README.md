
# AerialsDB

**Aerials** is a proof-of-concept project that rethinks data storage 
and management. Instead of relying on monolithic databases or file 
systems with rigid limits, it distributes data into small, self-contained 
SQLite3 buckets, along with central metadata tables.

This decentralized approach enhances scalability, flexibility, and fault 
tolerance. Each bucket is an independent SQLite file that stores 
**value** records, ensuring efficient handling of large datasets while 
minimizing the risks of data loss due to file corruption.

## Storage Layout

```
aerial.sq3
  |-- buckets table
  `-- buckets_meta table with keys

bucketroot/
|-- 28/
|   `-- dd/
|       `-- 1a21d3fdabf7.sq3
|           `-- bucket table with values
`-- f8/
    `-- 59/
        `-- 11cfd37ba0e2.sq3
            `-- bucket table
```

## Key Features

- **The main (central) database, `aerial.sq3`, stores information about 
  the buckets.** It contains the `buckets` and `buckets_meta` tables, 
  which map the locations where data is stored.

- **Data is divided into smaller databases called "buckets."** Each 
  bucket is an independent SQLite file containing values for appropriate 
  keys in the `buckets_meta` table.

- **New data insertion follows the `bucket_max_rows` rule.** Once a 
  bucket reaches its maximum row count, a new bucket is created.

- **Buckets are organized hierarchically within `bucketroot/`.** The 
  directory structure is derived from the first characters of a bucket's 
  hex identifier, ensuring an even file distribution.

- **Each bucket is relatively small,** minimizing the impact of file 
  corruption. Losing a single bucket means losing only a limited number 
  of records.

- **Bypassing filesystem limitations,** data is split into smaller 
  databases instead of a single large file, avoiding issues with file 
  count or size limits.

- **Lookups are handled via the central database.** A key is first 
  searched in `buckets_meta`, which determines the bucket where the 
  value is stored.

---

This decentralized approach, with small buckets, offers high flexibility, 
efficiency, and fault tolerance. Splitting data into small, independent 
files improves performance, minimizes data loss risks, and bypasses 
traditional filesystem limitations.
