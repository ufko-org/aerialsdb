# AerialsDB

Aerials is a **proof-of-concept** project designed to rethink how data is
stored and managed.  Instead of relying on monolithic databases or file
systems with hard limits, Aerials distributes data into discrete SQLite3
"buckets" and metadata tables, enabling high flexibility, scalability,
and enhanced data protection.

## Overview

Aerials separates data into two main parts:

- **Buckets**:
  - Each bucket stores data as simple key-value pairs.
  -	A bucket is essentially a micro filesystem.  What would be a normal file
  on disk is a row in the bucket table in the bucket's database file,
  where the key is the filename and the value is its content.
  - Buckets are automatically created when an existing bucket reaches a
  set maximum number of rows (defined by `bucket_max_rows` in the
  configuration).

- **Metadata (buckets_meta)**:
  - A separate table (`buckets_meta`) holds metadata about each bucket
  entry.
  - This metadata is stored as a JSON string, which acts like a “virtual
  table” schema.
  - The JSON can describe properties such as filename, size,
  description, creation date, etc.
  - If multiple rows in `buckets_meta` share the same JSON structure,
  it’s equivalent to having a virtual table with those JSON keys as
  columns.
  - This approach eliminates the need for a million hardcoded
  columns—each bucket row can be described uniquely and flexibly.

## Data Diagram

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

## Key Features

- **Flexibility**:
  - Use JSON in the metadata column to describe each bucket’s data.  For
  example, one record’s metadata could be:

    ```json
    {
      "file": "file.png",
      "size": "1024KB",
      "description": "Image file",
      "created": "2025-02-27"
    }
    ```

This is equivalent to having a virtual table with columns `file`,
`size`, `description`, `created`, plus the large data value stored
separately.

- **Data Protection & Risk Mitigation**:
  - Instead of having all data in one huge database file, each bucket is
  stored in its own SQLite file.  If one bucket is lost or corrupted,
  only about 10 records (as set by your bucket size) are affected rather
  than the entire dataset.
- **Scalability**:
  - Data is organized across multiple directories and database files.
  This not only helps overcome file system limitations on file and
  directory counts but also allows the system to scale gracefully as the
  dataset grows.
- **Efficient Backup & Recovery**:
  - Buckets can be dumped or backed up gradually, bucket by bucket,
  reducing the risk of overwhelming the system and allowing continuous
  operation.

## How It Works

- **Data Ingestion**:
  - When new data is added via the `bucket_set` function, the system
  checks the main buckets table for an available bucket (one that has
  fewer than 10 rows).
  - If an available bucket exists, the data (key and value) is inserted
  into that bucket’s SQLite file, and a corresponding entry is created
  in `buckets_meta` with its metadata (JSON).
  - If no available bucket exists, a new bucket is created in a new
  SQLite file located in a directory based on a generated bucket path.

- **Data Retrieval**:
  - The `bucket_get` function enables searching for a specific record by
  querying the `buckets_meta` table with a text search (using LIKE),
  treating the JSON as a simple text string.
  - Once the relevant bucket (and corresponding key) is found, the
  actual value is fetched from the associated bucket file.

- **Virtual Tables via JSON**:
  - Although the system uses only two main tables (`buckets_meta` for
  metadata and the per-bucket table for data), each JSON in
  `buckets_meta` acts as a flexible description of a “virtual table.”
  - If two rows share an identical JSON structure, it’s as if they
  belong to the same virtual table with custom columns, but the actual
  large data (the VALUE) is safely stored in a separate DB file.


## Usage Example

Imagine you want to store an image. The metadata might look like this:

```json
{
  "file": "file.png",
  "size": "1024KB",
  "description": "Image file",
  "created": "2025-02-27"
}
```

- This JSON acts as the schema for that particular record—defining
columns such as file, size, description, and created.
- The actual image (the VALUE) is stored in its own bucket database file
(e.g., bucketroot/0a/ed088ce1728d52.sq3).
- The system manages all buckets across various directories, ensuring
that if one bucket fails, only its limited number of records are affected.

## Conclusion

Aerials demonstrates just another approach to data storage by combining the
simplicity of key-value storage with the flexibility of JSON metadata,
all while protecting large data values in separate, manageable database
files.  This architecture is ideal for systems where data types vary,
and where risk mitigation and scalability are crucial.
