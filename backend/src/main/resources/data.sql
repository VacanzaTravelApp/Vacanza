-- =============================================================
-- Level Definitions
-- =============================================================
INSERT INTO level_definitions (level, min_xp, title) VALUES (1, 0, 'Newbie')         ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (2, 100, 'Explorer')      ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (3, 300, 'Traveler')      ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (4, 600, 'Adventurer')    ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (5, 1000, 'Urban Adventurer') ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (6, 1500, 'Pathfinder')   ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (7, 2200, 'Globetrotter') ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (8, 3000, 'Voyager')      ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (9, 4000, 'Legend')       ON CONFLICT (level) DO NOTHING;
INSERT INTO level_definitions (level, min_xp, title) VALUES (10, 5500, 'Grandmaster') ON CONFLICT (level) DO NOTHING;

-- =============================================================
-- Badge Definitions
-- =============================================================
INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('speed', 'First Step', 'Complete your first check-in', 'TOTAL_COUNT', NULL, 1)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('foodie', 'Foodie', 'Check in to 3 restaurants or cafes', 'CATEGORY_COUNT', 'restaurant,cafe', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('culture', 'Culture Buff', 'Check in to 3 museums, landmarks or historical sites', 'CATEGORY_COUNT', 'museum,landmark,historical', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('nature', 'Nature Lover', 'Check in to 3 parks, gardens or nature spots', 'CATEGORY_COUNT', 'park,garden,nature', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('explorer', 'Explorer', 'Check in to places across 3 different categories', 'CATEGORY_DIVERSITY', NULL, 3)
ON CONFLICT (badge_key) DO NOTHING;
