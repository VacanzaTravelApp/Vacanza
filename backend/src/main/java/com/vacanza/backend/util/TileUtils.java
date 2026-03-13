package com.vacanza.backend.util;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Slippy-map tile math for coverage tracking.
 * Converts between lat/lng bounding boxes and tile coordinates
 * using the standard OSM/Slippy Map tile numbering scheme.
 *
 * @see <a href="https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames">OSM Wiki</a>
 */
public final class TileUtils {

    public static final int DEFAULT_ZOOM = 14;

    private TileUtils() {
    }

    public static int lonToTileX(double lon, int zoom) {
        return (int) Math.floor((lon + 180.0) / 360.0 * (1 << zoom));
    }

    public static int latToTileY(double lat, int zoom) {
        double latRad = Math.toRadians(lat);
        return (int) Math.floor(
                (1.0 - Math.log(Math.tan(latRad) + 1.0 / Math.cos(latRad)) / Math.PI)
                        / 2.0 * (1 << zoom));
    }

    public static double tileXToLon(int x, int zoom) {
        return x / (double) (1 << zoom) * 360.0 - 180.0;
    }

    public static double tileYToLat(int y, int zoom) {
        double n = Math.PI - 2.0 * Math.PI * y / (double) (1 << zoom);
        return Math.toDegrees(Math.atan(Math.sinh(n)));
    }

    /**
     * Returns all tile coordinates that the given bbox overlaps at the specified zoom level.
     */
    public static List<TileCoord> tilesForBbox(
            double minLat, double minLng, double maxLat, double maxLng, int zoom) {

        int minTileX = lonToTileX(minLng, zoom);
        int maxTileX = lonToTileX(maxLng, zoom);
        int minTileY = latToTileY(maxLat, zoom);
        int maxTileY = latToTileY(minLat, zoom);

        List<TileCoord> tiles = new ArrayList<>();
        for (int x = minTileX; x <= maxTileX; x++) {
            for (int y = minTileY; y <= maxTileY; y++) {
                tiles.add(new TileCoord(x, y, zoom));
            }
        }
        return tiles;
    }

    /**
     * Converts a tile coordinate back to a lat/lng bounding box.
     */
    public static double[] tileToBbox(int tileX, int tileY, int zoom) {
        double minLng = tileXToLon(tileX, zoom);
        double maxLng = tileXToLon(tileX + 1, zoom);
        double maxLat = tileYToLat(tileY, zoom);
        double minLat = tileYToLat(tileY + 1, zoom);
        return new double[]{minLat, minLng, maxLat, maxLng};
    }

    /**
     * Builds a Geoapify rect filter string for a single tile.
     * Format: "rect:minLng,minLat,maxLng,maxLat"
     */
    public static String tileToRectFilter(int tileX, int tileY, int zoom) {
        double[] bbox = tileToBbox(tileX, tileY, zoom);
        return String.format(Locale.US, "rect:%f,%f,%f,%f",
                bbox[1], bbox[0], bbox[3], bbox[2]);
    }

    public record TileCoord(int x, int y, int zoom) {
    }
}
