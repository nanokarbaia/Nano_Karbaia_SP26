-- TASK 2 / INVESTIGATION RESULTS

-- a) Space consumption of public.table_to_delete before and after each operation

-- 1. After table creation:
-- row_estimate : -1.0
-- total size   : 575 MB
-- table size   : 575 MB
-- index size   : 0 bytes
-- toast size   : 8192 bytes

-- 2. After DELETE:
-- row_estimate : 9999898.0
-- total size   : 575 MB
-- table size   : 575 MB
-- index size   : 0 bytes
-- toast size   : 8192 bytes

-- 3. After VACUUM FULL:
-- row_estimate : 6666667.0
-- total size   : 383 MB
-- table size   : 383 MB
-- index size   : 0 bytes
-- toast size   : 8192 bytes

-- 4. After TRUNCATE:
-- row_estimate : 0.0
-- total size   : 8192 bytes
-- table size   : 0 bytes
-- index size   : 0 bytes
-- toast size   : 8192 bytes



-- b) Comparison of DELETE and TRUNCATE

-- 1. Execution time
-- DELETE took 18 seconds.
-- TRUNCATE took 1.227 seconds.
-- So, TRUNCATE was much faster than DELETE.

-- 2. Disk space usage
-- After DELETE, the number of rows was reduced, but the table size stayed the same: 575 MB.
-- This means DELETE removed rows logically, but did not immediately reduce the physical table size.
-- After VACUUM FULL, the size dropped from 575 MB to 383 MB.
-- After TRUNCATE, the table size became almost empty immediately: 8192 bytes total.

-- 3. Transaction behavior
-- DELETE works row by row and logs row-level changes.
-- TRUNCATE removes all rows at once and is handled more efficiently internally.
-- In PostgreSQL, both commands are transactional.
-- In this homework, autocommit was enabled, so each statement was committed automatically after execution.

-- 4. Rollback possibility
-- In PostgreSQL, both DELETE and TRUNCATE can be rolled back if they are executed inside an open transaction
-- and the transaction has not been committed yet.
-- In this case, because autocommit was turned on, the changes were committed automatically,
-- so rollback was not possible after execution.



-- c) Explanations

   
-- Why DELETE does not free space immediately:
   
-- DELETE marks rows as deleted, but it does not shrink the physical table file right away.
-- The freed space remains inside the table and can be reused later by PostgreSQL.
-- That is why the table size stayed 575 MB even after deleting 1/3 of the rows.

   
-- Why VACUUM FULL changes table size:
   
-- VACUUM FULL rewrites the table into a new compact version and removes dead space.
-- Because of that, it actually reduces the physical size of the table file.
-- In this investigation, after VACUUM FULL, the table size dropped from 575 MB to 383 MB.

   
-- Why TRUNCATE behaves differently:
   
-- TRUNCATE does not process rows one by one.
-- It removes all table data in a much more direct and efficient way.
-- That is why it was much faster than DELETE and reduced the table size almost immediately.

   
-- How these operations affect performance and storage:
   
-- DELETE is slower on large tables because it works row by row.
-- It can leave dead space, so storage is not reduced immediately.
-- VACUUM FULL can reclaim that space, but it is an additional operation.
-- TRUNCATE is much faster when all rows need to be removed,
-- and it is much more efficient in terms of storage cleanup.

   
-- Final conclusion:
   
-- If only specific rows need to be removed, DELETE should be used.
-- If all rows need to be removed, TRUNCATE is much faster and more storage-efficient.
-- If DELETE is used on a large table and physical size reduction is needed,
-- VACUUM FULL may be required afterwards.             