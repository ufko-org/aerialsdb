# AerialsDB

**Aerials is a proof-of-concept project** that rethinks data storage and
management.  Instead of relying on monolithic databases or file systems
with rigid limits, it distributes data into small, self-contained
SQLite3 buckets and central metadata tables.

This decentralized approach enhances scalability, flexibility, and fault
tolerance.  Each bucket is an independent SQLite file storing key-value
records, ensuring efficient handling of large datasets while mitigating
risks of data loss from file corruption.

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

### **Decentralized Data Storage with Small Buckets**  

#### **1. Bucket Size**  
Each bucket is intentionally kept small, containing only a 
limited number of records. This means that if a file gets 
corrupted (e.g., due to disk failure), only the records within 
that specific bucket are lost. This design significantly reduces 
the risk of large-scale data loss, improving the system’s 
resilience to failures.  

#### **2. Bypassing Filesystem (FS) Limitations**  
Since each bucket is stored as a separate SQLite file, this 
system effectively bypasses filesystem-imposed limitations. 
For instance, if a filesystem enforces a maximum file size 
(e.g., 4GB), splitting data into small buckets allows you to 
circumvent this restriction. This makes it possible to manage 
vast amounts of data that would otherwise be challenging to 
store in a single file.  

#### **3. Data Integrity and Fault Tolerance**  
Despite being decentralized and distributing data across 
multiple buckets, each bucket maintains its own metadata and 
database file stored on disk. If a file is corrupted or if a 
write operation fails, the system ensures data integrity 
through:  

- **Limited Damage**: If a bucket file becomes corrupted, only 
  the records within that specific bucket are affected. The 
  issue is constrained to a maximum of *N* records, ensuring 
  that the rest of the data remains intact and the system can 
  continue running without major disruption.  
- **Automatic Recovery**: If corruption is detected, the system 
  can implement recovery mechanisms such as replication or 
  restoring from a backup.  

#### **4. Decentralization Benefits**  
This architecture is highly efficient for applications requiring 
decentralized data storage. Since data is split into multiple 
small buckets, each operating independently, this structure 
offers:  

- **Fast Access & Scalability**: Distributing data across small 
  buckets improves search and write performance since each 
  bucket is managed separately.  
- **Increased Security**: In case of bucket failure, data loss 
  is minimal and only affects a small portion of the system.  
- **Flexibility & Scalability**: The system supports horizontal 
  scaling, where new buckets can be added seamlessly without 
  affecting existing data structures.  

#### **5. Storing Files in Buckets**  
Since the system is based on small SQLite files, it can be used 
to store larger files or data blocks. This method allows you to 
bypass filesystem constraints related to file size or directory 
limits.  

- **File Data in Small Chunks**: Files can be stored in these 
  buckets as binary data. This approach circumvents restrictions 
  when handling large files or datasets that would otherwise be 
  difficult to manage within a single file.  
- **File Distribution**: This method enables efficient 
  distribution of large files across multiple systems or nodes 
  without storing them as monolithic files, simplifying 
  management and scalability.  

---  
This decentralized approach with small buckets offers high 
flexibility, efficiency, and fault tolerance. Splitting data 
into small, independent files improves performance, minimizes 
data loss risks, and bypasses traditional filesystem 
limitations.
