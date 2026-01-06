-- This allows the database to instantly find coordinates without scanning the whole table.
CREATE INDEX idx_poi_location ON points_of_interest (latitude, longitude);