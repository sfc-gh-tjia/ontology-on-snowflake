-- =====================================================
-- SPCS Setup Script for Soccer Graph Analytics
-- =====================================================
-- Execute these commands in Snowflake Web UI

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE ONTOLOGY_DB;
USE SCHEMA SOCCER_KG;

-- Step 1: Create Image Repository
CREATE OR REPLACE IMAGE REPOSITORY soccer_graph_analytics_repo
  COMMENT = 'Repository for soccer graph analytics service Docker images with NetworkX';

SHOW IMAGE REPOSITORIES;

-- Step 2: Create Compute Pool
DROP COMPUTE POOL IF EXISTS soccer_graph_compute_pool;

CREATE COMPUTE POOL soccer_graph_compute_pool
  MIN_NODES = 1
  MAX_NODES = 3
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_RESUME = TRUE
  COMMENT = 'Compute pool for soccer graph analytics SPCS service with NetworkX';

-- Wait for compute pool to be ACTIVE before proceeding
SHOW COMPUTE POOLS;

-- Step 3: Create Stage for Service Specification
CREATE OR REPLACE STAGE soccer_graph_service_spec
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Stage for soccer graph analytics service specification';

-- Upload service.yaml to the stage:
-- Option A: Using SnowSQL CLI: PUT file://service.yaml @soccer_graph_service_spec;
-- Option B: Upload manually via Snowflake UI: Data → Databases → ONTOLOGY_DB → SOCCER_KG → Stages → soccer_graph_service_spec

-- Verify upload
LIST @soccer_graph_service_spec;

-- Step 4: Create SPCS Service
DROP SERVICE IF EXISTS soccer_graph_analytics_service;

CREATE SERVICE soccer_graph_analytics_service
  IN COMPUTE POOL soccer_graph_compute_pool
  FROM @"ONTOLOGY_DB"."SOCCER_KG"."SOCCER_GRAPH_SERVICE_SPEC"
  SPECIFICATION_FILE = 'service.yaml'
  MIN_INSTANCES = 1
  MAX_INSTANCES = 2
  COMMENT = 'Snowpark Container Services for advanced soccer graph analytics using NetworkX';

-- Step 5: Verify Deployment
SHOW SERVICES;
SHOW ENDPOINTS IN SERVICE soccer_graph_analytics_service;
SHOW SERVICE CONTAINERS IN SERVICE soccer_graph_analytics_service;

-- View service logs
SELECT SYSTEM$GET_SERVICE_LOGS('soccer_graph_analytics_service', '0', 'mcp-server', 100);

-- View detailed logs (line by line)
SELECT value AS log_entry
FROM TABLE(
    SPLIT_TO_TABLE(
        SYSTEM$GET_SERVICE_LOGS('soccer_graph_analytics_service', '0', 'mcp-server'),
        '\n'
    )
);

-- Service management commands (use as needed)
-- ALTER SERVICE soccer_graph_analytics_service SUSPEND;
-- ALTER SERVICE soccer_graph_analytics_service RESUME;
-- DESCRIBE SERVICE soccer_graph_analytics_service;
