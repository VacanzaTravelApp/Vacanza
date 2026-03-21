package com.vacanza.backend.util;

import java.util.ArrayList;
import java.util.List;

/**
 * Validation and helpers for map polygon rings (WGS84 lon/lat).
 */
public final class PolygonRouteGeometry {

    /** Maximum vertices in the outer ring (aligned with common client limits). */
    public static final int MAX_VERTICES = 200;

    /** Reject bounding-box area above this (km²) — conservative proxy for "too large". */
    public static final double MAX_BBOX_AREA_KM2 = 500.0;

    private PolygonRouteGeometry() {}

    /**
     * Normalizes input to an open ring (no repeated closing point).
     */
    public static List<double[]> normalizeRing(List<List<Double>> coordinates) {
        if (coordinates == null || coordinates.isEmpty()) {
            throw new IllegalArgumentException("coordinates required");
        }
        List<double[]> ring = new ArrayList<>();
        for (List<Double> pt : coordinates) {
            if (pt == null || pt.size() < 2) {
                continue;
            }
            Double lon = pt.get(0);
            Double lat = pt.get(1);
            if (lon == null || lat == null) {
                continue;
            }
            if (lon < -180 || lon > 180 || lat < -90 || lat > 90) {
                throw new IllegalArgumentException("coordinates out of WGS84 range");
            }
            ring.add(new double[] { lon, lat });
        }
        if (ring.size() >= 2) {
            double[] first = ring.get(0);
            double[] last = ring.get(ring.size() - 1);
            if (first[0] == last[0] && first[1] == last[1]) {
                ring.remove(ring.size() - 1);
            }
        }
        if (ring.size() < 3) {
            throw new IllegalArgumentException("polygon must have at least 3 distinct points");
        }
        if (ring.size() > MAX_VERTICES) {
            throw new IllegalArgumentException("too many vertices (max " + MAX_VERTICES + ")");
        }
        return ring;
    }

    public static double[] centroid(List<double[]> ring) {
        double slon = 0;
        double slat = 0;
        for (double[] p : ring) {
            slon += p[0];
            slat += p[1];
        }
        int n = ring.size();
        return new double[] { slon / n, slat / n };
    }

    public static double minLon(List<double[]> ring) {
        return ring.stream().mapToDouble(p -> p[0]).min().orElseThrow();
    }

    public static double maxLon(List<double[]> ring) {
        return ring.stream().mapToDouble(p -> p[0]).max().orElseThrow();
    }

    public static double minLat(List<double[]> ring) {
        return ring.stream().mapToDouble(p -> p[1]).min().orElseThrow();
    }

    public static double maxLat(List<double[]> ring) {
        return ring.stream().mapToDouble(p -> p[1]).max().orElseThrow();
    }

    /**
     * Approximate area of the axis-aligned bounding box of the ring in km².
     */
    public static double bboxAreaKm2(List<double[]> ring) {
        double minLon = minLon(ring);
        double maxLon = maxLon(ring);
        double minLat = minLat(ring);
        double maxLat = maxLat(ring);
        double midLat = (minLat + maxLat) / 2.0;
        double heightKm = (maxLat - minLat) * 111.0;
        double widthKm = (maxLon - minLon) * 111.0 * Math.cos(Math.toRadians(midLat));
        return Math.abs(heightKm * widthKm);
    }

    /**
     * Ray-casting point-in-polygon. Ring is open (first point not repeated at end).
     */
    public static boolean pointInPolygon(double lon, double lat, List<double[]> ring) {
        boolean inside = false;
        int n = ring.size();
        for (int i = 0, j = n - 1; i < n; j = i++) {
            double xi = ring.get(i)[0];
            double yi = ring.get(i)[1];
            double xj = ring.get(j)[0];
            double yj = ring.get(j)[1];
            boolean intersect = ((yi > lat) != (yj > lat))
                    && (lon < (xj - xi) * (lat - yi) / (yj - yi + 1e-30) + xi);
            if (intersect) {
                inside = !inside;
            }
        }
        return inside;
    }
}
