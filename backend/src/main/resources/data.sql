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
-- TOTAL_COUNT Badges
INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('speed', 'First Step', 'Complete your first check-in', 'TOTAL_COUNT', NULL, 1)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('novice', 'Novice Checker', 'Complete 5 check-ins', 'TOTAL_COUNT', NULL, 5)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('frequent', 'Frequent Flyer', 'Complete 25 check-ins', 'TOTAL_COUNT', NULL, 25)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('master', 'Check-in Master', 'Complete 50 check-ins', 'TOTAL_COUNT', NULL, 50)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('legendary_checker', 'Legendary', 'Complete 100 check-ins', 'TOTAL_COUNT', NULL, 100)
ON CONFLICT (badge_key) DO NOTHING;

-- CATEGORY_COUNT Badges
INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('foodie', 'Foodie', 'Check in to 3 restaurants or cafes', 'CATEGORY_COUNT', 'restaurant,cafe', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('foodie_pro', 'Pro Foodie', 'Check in to 10 restaurants or cafes', 'CATEGORY_COUNT', 'restaurant,cafe', 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('foodie_master', 'Master Foodie', 'Check in to 25 restaurants or cafes', 'CATEGORY_COUNT', 'restaurant,cafe', 25)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('culture', 'Culture Buff', 'Check in to 3 museums, landmarks or historical sites', 'CATEGORY_COUNT', 'museum,landmark,historical', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('culture_pro', 'Culture Pro', 'Check in to 10 museums, landmarks or historical sites', 'CATEGORY_COUNT', 'museum,landmark,historical', 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('culture_master', 'Culture Master', 'Check in to 25 museums, landmarks or historical sites', 'CATEGORY_COUNT', 'museum,landmark,historical', 25)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('nature', 'Nature Lover', 'Check in to 3 parks, gardens or nature spots', 'CATEGORY_COUNT', 'park,garden,nature', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('nature_pro', 'Nature Pro', 'Check in to 10 parks, gardens or nature spots', 'CATEGORY_COUNT', 'park,garden,nature', 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('nature_master', 'Nature Master', 'Check in to 25 parks, gardens or nature spots', 'CATEGORY_COUNT', 'park,garden,nature', 25)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('nightowl', 'Night Owl', 'Check in to 3 bars or clubs', 'CATEGORY_COUNT', 'bar,club,night_club', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('nightowl_pro', 'Party Animal', 'Check in to 10 bars or clubs', 'CATEGORY_COUNT', 'bar,club,night_club', 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('shopper', 'Shopper', 'Check in to 3 stores or malls', 'CATEGORY_COUNT', 'store,shopping_mall', 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('shopper_pro', 'Shopaholic', 'Check in to 10 stores or malls', 'CATEGORY_COUNT', 'store,shopping_mall', 10)
ON CONFLICT (badge_key) DO NOTHING;

-- CATEGORY_DIVERSITY Badges
INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('explorer', 'Explorer', 'Check in to places across 3 different categories', 'CATEGORY_DIVERSITY', NULL, 3)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('world_traveler', 'World Traveler', 'Check in to places across 5 different categories', 'CATEGORY_DIVERSITY', NULL, 5)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('polymath', 'Polymath', 'Check in to places across 10 different categories', 'CATEGORY_DIVERSITY', NULL, 10)
ON CONFLICT (badge_key) DO NOTHING;

-- =============================================================
-- New Badges: Additional Upstream Values
-- =============================================================
INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('regular', 'Regular', 'Complete 10 check-ins', 'TOTAL_COUNT', NULL, 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('local_expert', 'Local Expert', 'Complete 50 check-ins', 'TOTAL_COUNT', NULL, 50)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('gourmet', 'Gourmet', 'Check in to 10 restaurants or cafes', 'CATEGORY_COUNT', 'restaurant,cafe', 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('historian', 'Historian', 'Check in to 10 museums, landmarks or historical sites', 'CATEGORY_COUNT', 'museum,landmark,historical', 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('outdoorsman', 'Outdoorsman', 'Check in to 10 parks, gardens or nature spots', 'CATEGORY_COUNT', 'park,garden,nature', 10)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('night_owl', 'Night Owl', 'Check in to 5 bars, clubs or nightlife spots', 'CATEGORY_COUNT', 'bar,night_club,nightlife', 5)
ON CONFLICT (badge_key) DO NOTHING;

INSERT INTO badges (badge_key, title, description, criteria_type, criteria_category, criteria_threshold)
VALUES ('shopaholic', 'Shopaholic', 'Check in to 5 stores or shopping malls', 'CATEGORY_COUNT', 'shopping_mall,store', 5)
ON CONFLICT (badge_key) DO NOTHING;
