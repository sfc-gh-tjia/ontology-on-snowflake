-- =====================================================
-- LAYER 2: ONTOLOGY METADATA LAYER
-- Metadata tables that define the ontology structure
-- =====================================================

USE DATABASE ONTOLOGY_DB;
USE SCHEMA SOCCER_KG;

-- =====================================================
-- ONTOLOGY REGISTRY
-- =====================================================
CREATE OR REPLACE TABLE ONT_ONTOLOGY (
    ONTOLOGY_NAME STRING PRIMARY KEY,
    DESCRIPTION STRING,
    VERSION STRING,
    DEFAULT_SCHEMA STRING,
    CREATED_BY STRING,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    IS_ACTIVE BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE ONT_ONTOLOGY IS 'Registry of ontologies with versioning';

-- =====================================================
-- OBJECT TYPE SOURCE MAPPINGS
-- =====================================================
CREATE OR REPLACE TABLE ONT_OBJECT_SOURCE (
    ONTOLOGY_NAME STRING,
    CLASS_NAME STRING,          -- e.g. 'PLAYER'
    SOURCE_TYPE STRING,         -- 'DATASET' | 'VIEW' | 'MODEL'
    SOURCE_REF STRING,          -- full reference like 'DB.SCHEMA.TABLE'
    PRIMARY KEY (ONTOLOGY_NAME, CLASS_NAME, SOURCE_REF)
);

COMMENT ON TABLE ONT_OBJECT_SOURCE IS 'Maps object types to their source datasets';

CREATE OR REPLACE TABLE ONT_LINK_SOURCE (
    ONTOLOGY_NAME STRING,
    REL_NAME STRING,
    SOURCE_TYPE STRING,         -- 'EDGE_TABLE' | 'PIPELINE'
    SOURCE_REF STRING,
    PRIMARY KEY (ONTOLOGY_NAME, REL_NAME, SOURCE_REF)
);

COMMENT ON TABLE ONT_LINK_SOURCE IS 'Maps link types to their source edge tables';

-- =====================================================
-- CLASS DEFINITIONS (Object Types)
-- =====================================================
CREATE OR REPLACE TABLE ONT_CLASS (
    CLASS_NAME STRING PRIMARY KEY,
    PARENT_CLASS_NAME STRING,
    IS_ABSTRACT BOOLEAN DEFAULT FALSE,
    DESCRIPTION STRING,
    ONTOLOGY_NAME STRING,
    TYPE_CLASS STRING,          -- 'ANALYTICAL' | 'OPERATIONAL'
    STATUS STRING DEFAULT 'ACTIVE',
    TS_CREATED TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

COMMENT ON TABLE ONT_CLASS IS 'Object type definitions with class hierarchy';

-- =====================================================
-- RELATIONSHIP DEFINITIONS (Link Types)
-- =====================================================
CREATE OR REPLACE TABLE ONT_RELATION_DEF (
    REL_NAME STRING PRIMARY KEY,
    DOMAIN_CLASS STRING,        -- source class
    RANGE_CLASS STRING,         -- target class
    CARDINALITY STRING,         -- N:1 | 1:N | N:N | 1:1
    IS_HIERARCHICAL BOOLEAN DEFAULT FALSE,
    INVERSE_REL_NAME STRING,
    DESCRIPTION STRING,
    ONTOLOGY_NAME STRING,
    STATUS STRING DEFAULT 'ACTIVE',
    RENDER_HINT STRING          -- 'directed' | 'undirected' | 'hierarchical'
);

COMMENT ON TABLE ONT_RELATION_DEF IS 'Link type definitions with cardinality and constraints';

-- =====================================================
-- PROPERTY DEFINITIONS
-- =====================================================
CREATE OR REPLACE TABLE ONT_SHARED_PROPERTY (
    SHARED_PROP_NAME STRING PRIMARY KEY,   -- e.g. 'name', 'country'
    BASE_TYPE STRING,                      -- 'STRING','NUMBER', etc.
    DESCRIPTION STRING,
    DEFAULT_FORMAT STRING
);

COMMENT ON TABLE ONT_SHARED_PROPERTY IS 'Shared properties reusable across object types';

CREATE OR REPLACE TABLE ONT_PROPERTY (
    CLASS_NAME STRING,
    PROP_NAME STRING,
    DATA_TYPE STRING,                      -- 'STRING','NUMBER','DATE', etc.
    SHARED_PROP_NAME STRING,               -- FK to shared property
    IS_REQUIRED BOOLEAN DEFAULT FALSE,
    IS_INDEXED BOOLEAN DEFAULT FALSE,
    DESCRIPTION STRING,
    PRIMARY KEY (CLASS_NAME, PROP_NAME)
);

COMMENT ON TABLE ONT_PROPERTY IS 'Properties for each object type';

CREATE OR REPLACE TABLE ONT_DERIVED_PROPERTY (
    CLASS_NAME STRING,
    PROP_NAME STRING,
    DEFINITION_KIND STRING,                -- 'SQL','FUNCTION'
    SQL_EXPR STRING,                       -- if definition_kind = 'SQL'
    FUNCTION_NAME STRING,                  -- if definition_kind = 'FUNCTION'
    DESCRIPTION STRING,
    PRIMARY KEY (CLASS_NAME, PROP_NAME)
);

COMMENT ON TABLE ONT_DERIVED_PROPERTY IS 'Computed/derived properties with their definitions';

-- =====================================================
-- INFERENCE RULES
-- =====================================================
CREATE OR REPLACE TABLE ONT_RULE (
    RULE_ID STRING PRIMARY KEY,
    RULE_KIND STRING,                      -- TRANSITIVE | PROPERTY_CHAIN | INVERSE
    TARGET_REL STRING,                     -- relationship to infer
    SOURCE_REL_1 STRING,
    SOURCE_REL_2 STRING,                   -- for property chain
    INVERSE_OF STRING,                     -- for inverse rules
    DESCRIPTION STRING,
    IS_ENABLED BOOLEAN DEFAULT TRUE,
    TS_CREATED TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

COMMENT ON TABLE ONT_RULE IS 'Inference rules for deriving new relationships';

-- =====================================================
-- DATA QUALITY CONSTRAINTS
-- =====================================================
CREATE OR REPLACE TABLE ONT_CONSTRAINT_VIOLATION (
    VIOLATION_ID STRING DEFAULT UUID_STRING(),
    CHECK_NAME STRING,
    SCOPE STRING,                          -- RELATION | CLASS | GLOBAL
    REL_OR_CLASS STRING,
    SRC_ID STRING,
    DST_ID STRING,
    DETAILS STRING,
    OBSERVED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (VIOLATION_ID)
);

COMMENT ON TABLE ONT_CONSTRAINT_VIOLATION IS 'Log of data quality constraint violations';

-- =====================================================
-- ACTIONS (Operations)
-- =====================================================
CREATE OR REPLACE TABLE ACT_TYPE (
    ACTION_TYPE_ID STRING PRIMARY KEY,
    ACTION_NAME STRING NOT NULL,
    DESCRIPTION STRING,
    ONTOLOGY_NAME STRING,
    TARGET_CLASS STRING,                   -- object type this action applies to
    HANDLER_PROC STRING,                   -- stored procedure reference
    IS_ENABLED BOOLEAN DEFAULT TRUE,
    TS_CREATED TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

COMMENT ON TABLE ACT_TYPE IS 'Action type definitions - operations that can be performed on objects';

CREATE OR REPLACE TABLE ACT_DEF (
    ACTION_TYPE_ID STRING,
    PARAM_NAME STRING,
    PARAM_TYPE STRING,                     -- 'STRING' | 'NUMBER' | 'DATE' | 'BOOLEAN'
    IS_REQUIRED BOOLEAN DEFAULT FALSE,
    DESCRIPTION STRING,
    PRIMARY KEY (ACTION_TYPE_ID, PARAM_NAME)
);

COMMENT ON TABLE ACT_DEF IS 'Action parameter definitions';

CREATE OR REPLACE TABLE ACT_INVOCATION (
    INVOCATION_ID STRING PRIMARY KEY,
    ACTION_TYPE_ID STRING NOT NULL,
    TARGET_OBJECT_ID STRING,
    PARAMS VARIANT,
    STATUS STRING,                         -- 'PENDING' | 'SUCCESS' | 'FAILED'
    RESULT_MSG STRING,
    INVOKED_BY STRING,
    INVOKED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    COMPLETED_AT TIMESTAMP_NTZ
);

COMMENT ON TABLE ACT_INVOCATION IS 'Log of action invocations';

-- =====================================================
-- CLASS AND RELATIONSHIP MAPPINGS
-- =====================================================
CREATE OR REPLACE TABLE ONT_CLASS_MAP (
    CLASS_NAME STRING,
    CONCRETE_VIEW STRING,
    ID_COL STRING DEFAULT 'NODE_ID',
    PROPS_COL STRING DEFAULT 'PROPS',
    PRIMARY KEY (CLASS_NAME, CONCRETE_VIEW)
);

COMMENT ON TABLE ONT_CLASS_MAP IS 'Maps abstract classes to concrete views for view generation';

CREATE OR REPLACE TABLE ONT_REL_MAP (
    REL_NAME STRING,
    CONCRETE_VIEW STRING,
    SRC_COL STRING,
    DST_COL STRING,
    PROPS_COL STRING DEFAULT 'PROPS',
    PRIMARY KEY (REL_NAME, CONCRETE_VIEW)
);

COMMENT ON TABLE ONT_REL_MAP IS 'Maps abstract relationships to concrete views';

-- =====================================================
-- INTERFACES (Polymorphism)
-- =====================================================
CREATE OR REPLACE TABLE ONT_INTERFACE (
    INTERFACE_NAME STRING PRIMARY KEY,     -- e.g. 'PERSON', 'COMPETITION_MEMBER'
    DESCRIPTION STRING
);

COMMENT ON TABLE ONT_INTERFACE IS 'Interface definitions for polymorphism';

CREATE OR REPLACE TABLE ONT_INTERFACE_PROPERTY (
    INTERFACE_NAME STRING,
    PROP_NAME STRING,
    SHARED_PROP_NAME STRING,
    PRIMARY KEY (INTERFACE_NAME, PROP_NAME)
);

COMMENT ON TABLE ONT_INTERFACE_PROPERTY IS 'Properties required by each interface';

CREATE OR REPLACE TABLE ONT_INTERFACE_IMPL (
    INTERFACE_NAME STRING,
    CLASS_NAME STRING,
    PRIMARY KEY (INTERFACE_NAME, CLASS_NAME)
);

COMMENT ON TABLE ONT_INTERFACE_IMPL IS 'Maps which classes implement which interfaces';

-- =====================================================
-- FUNCTION CATALOG
-- =====================================================
CREATE OR REPLACE TABLE ONT_FUNCTION (
    FUNCTION_NAME STRING,                  -- logical name in ontology
    VERSION STRING,
    LANGUAGE STRING,                       -- 'SQL','PYTHON','JS','EXTERNAL'
    SNOWFLAKE_REF STRING,                  -- actual Snowflake function reference
    DESCRIPTION STRING,
    INPUT_SCHEMA VARIANT,
    OUTPUT_SCHEMA VARIANT,
    ONTOLOGY_NAME STRING,
    PRIMARY KEY (ONTOLOGY_NAME, FUNCTION_NAME, VERSION)
);

COMMENT ON TABLE ONT_FUNCTION IS 'Ontology function catalog - versioned code artifacts';

CREATE OR REPLACE TABLE ONT_FUNCTION_BINDING (
    ONTOLOGY_NAME STRING,
    FUNCTION_NAME STRING,
    VERSION STRING,
    BOUND_TO_KIND STRING,                  -- 'OBJECT_TYPE','LINK_TYPE','ACTION_TYPE'
    BOUND_TO_NAME STRING
);

COMMENT ON TABLE ONT_FUNCTION_BINDING IS 'Binds functions to object types, link types, or action types';

-- =====================================================
-- OBJECT VIEWS (UI Configuration)
-- =====================================================
CREATE OR REPLACE TABLE OBJ_VIEW_DEF (
    VIEW_NAME STRING,                      -- logical view name, e.g. 'PlayerProfile'
    CLASS_NAME STRING,
    VERSION STRING DEFAULT '1.0',
    VIEW_KIND STRING,                      -- 'FULL' | 'PANEL' | 'LIST'
    SQL_REF STRING,
    STATUS STRING DEFAULT 'ACTIVE',
    PRIMARY KEY (CLASS_NAME, VIEW_NAME, VERSION)
);

COMMENT ON TABLE OBJ_VIEW_DEF IS 'Object view definitions for UI presentation';

CREATE OR REPLACE TABLE OBJ_VIEW_FIELD (
    CLASS_NAME STRING,
    VIEW_NAME STRING,
    VERSION STRING DEFAULT '1.0',
    FIELD_ORDER NUMBER,
    PROP_NAME STRING,
    RENDER_HINT STRING,                    -- 'badge' | 'link' | 'date' | 'number'
    PRIMARY KEY (CLASS_NAME, VIEW_NAME, VERSION, PROP_NAME)
);

COMMENT ON TABLE OBJ_VIEW_FIELD IS 'Field configuration for object views';

-- =====================================================
-- PERMISSIONS AND ROLES
-- =====================================================
CREATE OR REPLACE TABLE ONT_ROLE (
    ONTOLOGY_NAME STRING,
    ONT_ROLE_NAME STRING,
    DESCRIPTION STRING,
    PRIMARY KEY (ONTOLOGY_NAME, ONT_ROLE_NAME)
);

COMMENT ON TABLE ONT_ROLE IS 'Ontology-specific roles for access control';

CREATE OR REPLACE TABLE ONT_ROLE_BINDING (
    ONTOLOGY_NAME STRING,
    ONT_ROLE_NAME STRING,
    SNOWFLAKE_ROLE STRING,
    PRIMARY KEY (ONTOLOGY_NAME, ONT_ROLE_NAME, SNOWFLAKE_ROLE)
);

COMMENT ON TABLE ONT_ROLE_BINDING IS 'Maps ontology roles to Snowflake roles';

CREATE OR REPLACE TABLE ONT_PERMISSION (
    ONTOLOGY_NAME STRING,
    SUBJECT_KIND STRING,                   -- 'OBJECT_TYPE','LINK_TYPE','ACTION_TYPE'
    SUBJECT_NAME STRING,
    ONT_ROLE_NAME STRING,
    PRIVILEGE STRING,                      -- 'READ','WRITE','EXECUTE','ADMIN'
    PRIMARY KEY (ONTOLOGY_NAME, SUBJECT_KIND, SUBJECT_NAME, ONT_ROLE_NAME, PRIVILEGE)
);

COMMENT ON TABLE ONT_PERMISSION IS 'Granular permissions for object types, link types, and actions';

-- =====================================================
-- INFERRED EDGES
-- =====================================================
CREATE OR REPLACE TABLE REL_EDGE_INFERRED (
    REL_NAME STRING NOT NULL,
    SRC_ID STRING NOT NULL,
    DST_ID STRING NOT NULL,
    INFERENCE_KIND STRING,                 -- 'TRANSITIVE','INVERSE','PROPERTY_CHAIN'
    RULE_ID STRING,
    WEIGHT FLOAT DEFAULT 1.0,
    EFFECTIVE_START DATE,
    EFFECTIVE_END DATE,
    COMPUTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (REL_NAME, SRC_ID, DST_ID, RULE_ID)
);

COMMENT ON TABLE REL_EDGE_INFERRED IS 'Inferred relationships generated by inference rules';

-- =====================================================
-- CLASS CLOSURE (Hierarchy)
-- =====================================================
CREATE OR REPLACE VIEW ONT_CLASS_CLOSURE AS
WITH RECURSIVE closure(ancestor, descendant, depth) AS (
    -- Base case: each class is its own descendant at depth 0
    SELECT CLASS_NAME, CLASS_NAME, 0
    FROM ONT_CLASS
    UNION ALL
    -- Recursive case: follow parent links
    SELECT closure.ancestor, child.CLASS_NAME, closure.depth + 1
    FROM closure
    JOIN ONT_CLASS child ON child.PARENT_CLASS_NAME = closure.descendant
    WHERE closure.depth < 10  -- prevent infinite loops
)
SELECT DISTINCT ancestor, descendant, depth
FROM closure;

COMMENT ON VIEW ONT_CLASS_CLOSURE IS 'Transitive closure of class hierarchy - shows all ancestor-descendant relationships';

-- =====================================================
-- RESOLVED RELATIONSHIPS VIEW
-- Combines explicit edges with inferred edges
-- =====================================================
CREATE OR REPLACE VIEW REL_RESOLVED AS
SELECT 
    EDGE_TYPE AS REL_NAME, 
    SRC_ID, 
    DST_ID, 
    WEIGHT, 
    EFFECTIVE_START, 
    EFFECTIVE_END,
    'EXPLICIT' AS SOURCE
FROM KG_EDGE
UNION ALL
SELECT 
    REL_NAME, 
    SRC_ID, 
    DST_ID, 
    WEIGHT, 
    EFFECTIVE_START, 
    EFFECTIVE_END,
    'INFERRED' AS SOURCE
FROM REL_EDGE_INFERRED;

COMMENT ON VIEW REL_RESOLVED IS 'Unified view of explicit and inferred relationships';
