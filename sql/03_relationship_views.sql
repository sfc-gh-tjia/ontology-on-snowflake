-- =====================================================
-- LAYER 3: RELATIONSHIP VIEWS (Convenience Views)
-- Type-specific views over KG_EDGE for easier querying
-- =====================================================

USE DATABASE ONTOLOGY_DB;
USE SCHEMA SOCCER_KG;

-- =====================================================
-- V_PLAYS_FOR: Player-to-Club relationships
-- =====================================================
CREATE OR REPLACE VIEW V_PLAYS_FOR AS
SELECT
    SRC_ID                AS PLAYER_ID,
    DST_ID                AS CLUB_ID,
    EDGE_TYPE,
    PROPS,
    WEIGHT,
    EFFECTIVE_START,
    EFFECTIVE_END,
    PROPS:jersey_number::INTEGER      AS JERSEY_NUMBER,
    PROPS:contract_value::DECIMAL(15,2) AS CONTRACT_VALUE
FROM KG_EDGE
WHERE EDGE_TYPE = 'PLAYS_FOR';

COMMENT ON VIEW V_PLAYS_FOR IS 'Player-to-Club contract relationships with extracted properties';

-- =====================================================
-- V_COACHES: Coach-to-Club relationships
-- =====================================================
CREATE OR REPLACE VIEW V_COACHES AS
SELECT
    SRC_ID                AS COACH_ID,
    DST_ID                AS CLUB_ID,
    EDGE_TYPE,
    PROPS,
    WEIGHT,
    EFFECTIVE_START,
    EFFECTIVE_END,
    PROPS:contract_value::DECIMAL(15,2) AS CONTRACT_VALUE
FROM KG_EDGE
WHERE EDGE_TYPE = 'COACHES';

COMMENT ON VIEW V_COACHES IS 'Coach-to-Club contract relationships with extracted properties';

-- =====================================================
-- V_PLAYED_IN: Player-to-Match relationships (appearances)
-- =====================================================
CREATE OR REPLACE VIEW V_PLAYED_IN AS
SELECT
    SRC_ID                AS PLAYER_ID,
    DST_ID                AS MATCH_ID,
    EDGE_TYPE,
    PROPS,
    WEIGHT,
    EFFECTIVE_START,
    EFFECTIVE_END,
    PROPS:minutes_played::INTEGER  AS MINUTES_PLAYED,
    PROPS:goals_scored::INTEGER    AS GOALS_SCORED,
    PROPS:assists::INTEGER         AS ASSISTS,
    PROPS:yellow_cards::INTEGER    AS YELLOW_CARDS,
    PROPS:red_cards::INTEGER       AS RED_CARDS
FROM KG_EDGE
WHERE EDGE_TYPE = 'PLAYED_IN';

COMMENT ON VIEW V_PLAYED_IN IS 'Player match appearances with performance statistics';

-- =====================================================
-- V_HOME_TEAM: Club-to-Match relationships (home team)
-- =====================================================
CREATE OR REPLACE VIEW V_HOME_TEAM AS
SELECT
    SRC_ID                AS CLUB_ID,
    DST_ID                AS MATCH_ID,
    EDGE_TYPE,
    PROPS,
    WEIGHT,
    EFFECTIVE_START,
    EFFECTIVE_END
FROM KG_EDGE
WHERE EDGE_TYPE = 'HOME_TEAM';

COMMENT ON VIEW V_HOME_TEAM IS 'Club-to-Match relationship for home team designation';

-- =====================================================
-- V_AWAY_TEAM: Club-to-Match relationships (away team)
-- =====================================================
CREATE OR REPLACE VIEW V_AWAY_TEAM AS
SELECT
    SRC_ID                AS CLUB_ID,
    DST_ID                AS MATCH_ID,
    EDGE_TYPE,
    PROPS,
    WEIGHT,
    EFFECTIVE_START,
    EFFECTIVE_END
FROM KG_EDGE
WHERE EDGE_TYPE = 'AWAY_TEAM';

COMMENT ON VIEW V_AWAY_TEAM IS 'Club-to-Match relationship for away team designation';

-- =====================================================
-- CONVENIENCE VIEWS FOR ACTIVE DATA
-- =====================================================

-- Currently active players (with active contracts)
CREATE OR REPLACE VIEW ACTIVE_PLAYERS AS
SELECT 
    p.NODE_ID AS PERSON_ID,
    p.NAME,
    p.POSITION,
    p.NATIONALITY,
    c.NAME AS CLUB_NAME,
    pf.EFFECTIVE_START AS CONTRACT_START,
    pf.EFFECTIVE_END AS CONTRACT_END
FROM V_PLAYER p
JOIN V_PLAYS_FOR pf ON p.NODE_ID = pf.PLAYER_ID
JOIN V_CLUB c ON pf.CLUB_ID = c.NODE_ID
WHERE pf.EFFECTIVE_END IS NULL OR pf.EFFECTIVE_END >= CURRENT_DATE();

COMMENT ON VIEW ACTIVE_PLAYERS IS 'Players with currently active contracts';

-- Currently active coaches (with active contracts)
CREATE OR REPLACE VIEW ACTIVE_COACHES AS
SELECT 
    p.NODE_ID AS PERSON_ID,
    p.NAME,
    p.NATIONALITY,
    c.NAME AS CLUB_NAME,
    co.EFFECTIVE_START AS CONTRACT_START,
    co.EFFECTIVE_END AS CONTRACT_END
FROM V_COACH p
JOIN V_COACHES co ON p.NODE_ID = co.COACH_ID
JOIN V_CLUB c ON co.CLUB_ID = c.NODE_ID
WHERE co.EFFECTIVE_END IS NULL OR co.EFFECTIVE_END >= CURRENT_DATE();

COMMENT ON VIEW ACTIVE_COACHES IS 'Coaches with currently active contracts';

-- Match results with team names
CREATE OR REPLACE VIEW MATCH_RESULTS AS
SELECT 
    m.NODE_ID AS MATCH_ID,
    m.NAME AS MATCH_NAME,
    m.EVENT_DATE,
    m.COMPETITION,
    m.VENUE,
    hc.NAME AS HOME_TEAM,
    m.SCORE_HOME,
    ac.NAME AS AWAY_TEAM,
    m.SCORE_AWAY,
    CASE 
        WHEN m.SCORE_HOME > m.SCORE_AWAY THEN hc.NAME
        WHEN m.SCORE_AWAY > m.SCORE_HOME THEN ac.NAME
        ELSE 'Draw'
    END AS WINNER
FROM V_MATCH m
LEFT JOIN V_HOME_TEAM ht ON m.NODE_ID = ht.MATCH_ID
LEFT JOIN V_CLUB hc ON ht.CLUB_ID = hc.NODE_ID
LEFT JOIN V_AWAY_TEAM at ON m.NODE_ID = at.MATCH_ID
LEFT JOIN V_CLUB ac ON at.CLUB_ID = ac.NODE_ID;

COMMENT ON VIEW MATCH_RESULTS IS 'Match results with resolved team names';
