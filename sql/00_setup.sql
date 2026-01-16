-- =====================================================
-- ONTOLOGY ON SNOWFLAKE - SETUP SCRIPT
-- Creates database and schema for the soccer knowledge graph
-- =====================================================

-- Create database
CREATE OR REPLACE DATABASE ONTOLOGY_DB;
USE DATABASE ONTOLOGY_DB;

-- Create schema
CREATE OR REPLACE SCHEMA SOCCER_KG;
USE SCHEMA SOCCER_KG;

-- Grant basic permissions (adjust as needed)
-- GRANT USAGE ON DATABASE ONTOLOGY_DB TO ROLE PUBLIC;
-- GRANT USAGE ON SCHEMA ONTOLOGY_DB.SOCCER_KG TO ROLE PUBLIC;

COMMENT ON DATABASE ONTOLOGY_DB IS 'Ontology on Snowflake - Soccer Knowledge Graph Demo';
COMMENT ON SCHEMA SOCCER_KG IS 'Soccer knowledge graph with ontology metadata layer';
