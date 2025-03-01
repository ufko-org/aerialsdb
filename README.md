
# AerialsDB

**Aerials is a proof-of-concept project** that rethinks data storage and
management. Instead of relying on monolithic databases or file systems
with rigid limits, it distributes data into small, self-contained
SQLite3 buckets, along with central metadata tables.

This decentralized approach enhances scalability, flexibility, and fault
tolerance. Each bucket is an independent SQLite file that stores
key-value records, ensuring efficient handling of large datasets while
minimizing the risks of data loss due to file corruption.

## Storage Layout

```
aerial.sq3
  |-- buckets table
  `-- buckets_meta table

bucketroot/
|-- 28/
|   `-- dd/
|       `-- 1a21d3fdabf7.sq3
|           `-- bucket table
`-- f8/
    `-- 59/
        `-- 11cfd37ba0e2.sq3
            `-- bucket table
```

## Key features

1. **Data is divided into smaller databases called "buckets"** –  
   each bucket is an independent SQLite file containing key-value  
   records.  

2. **The main (central) database `aerial.sq3` only stores indexes** –  
   it contains `buckets` and `buckets_meta` tables, which map where  
   data is stored.  

3. **Buckets are organized hierarchically within `bucketroot/`** –  
   the directory structure is derived from the first characters of  
   a bucket's hex identifier, ensuring an even file distribution.  

4. **Each bucket is relatively small**, minimizing the impact of  
   file corruption – losing a single bucket means losing only N  
   records.  

5. **Bypassing filesystem limitations** – instead of a single  
   large file, data is split into smaller databases, avoiding  
   issues with file count or size limits.  

6. **New data insertion follows the `bucket_max_rows` rule** –  
   once a bucket reaches its maximum row count, a new bucket is  
   created.  

7. **Lookups are handled via the central database** – a key  
   (`key`) is first searched in `buckets_meta`, which determines  
   in which bucket the value is stored.  

--  

This decentralized approach with small buckets offers high 
flexibility, efficiency, and fault tolerance. Splitting data 
into small, independent files improves performance, minimizes 
data loss risks, and bypasses traditional filesystem 
limitations.
