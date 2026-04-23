"""Unit tests for chat_service post-processing functions.

These functions run after every LLM response and directly affect route quality.
No DB, no LLM calls — pure unit tests on deterministic logic.
"""

import pytest

from app.schemas.chat import DayPlan, RouteData, RouteWaypoint
from app.services.chat_service import (
    _fix_dining_proximity,
    _fix_duplicate_waypoints,
    _fix_opening_hours,
    _fix_route_dining,
    _fix_geographic_spread,
    _is_trivial_message,
    _optimize_route_order,
)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _wp(
    name: str,
    category: str,
    order: int,
    day: int = 1,
    lat: float | None = None,
    lon: float | None = None,
    duration: int = 60,
    time_slot: str = "morning",
) -> RouteWaypoint:
    return RouteWaypoint(
        name=name,
        category=category,
        day=day,
        order=order,
        latitude=lat,
        longitude=lon,
        estimated_duration_min=duration,
        time_slot=time_slot,
    )


def _route(*days: DayPlan, destination: str = "Istanbul, Turkey", total_days: int | None = None) -> RouteData:
    return RouteData(
        title="Test Route",
        destination=destination,
        total_days=total_days if total_days is not None else len(days),
        days=list(days),
    )


def _day(*waypoints: RouteWaypoint, day_num: int = 1, start: str = "09:00") -> DayPlan:
    return DayPlan(day=day_num, title=f"Day {day_num}", waypoints=list(waypoints), day_start_local=start)


# ── _fix_route_dining ─────────────────────────────────────────────────────────

class TestFixRouteDining:
    def test_restaurant_in_first_slot_moves_back(self):
        # Non-dining target must exist beyond index 2 for the swap to trigger
        wps = [
            _wp("Lunch Spot", "restaurant", 1),
            _wp("Museum A", "museum", 2),
            _wp("Museum B", "museum", 3),
            _wp("Museum C", "museum", 4),
            _wp("Dinner Spot", "restaurant", 5, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_route_dining(route)
        cats = [w.category for w in result.days[0].waypoints]
        # restaurant must NOT be in slot 0 (index 0) after fix
        assert cats[0] != "restaurant"

    def test_adjacent_dining_stops_are_separated(self):
        # cafe immediately followed by restaurant — two non-dining stops available to swap
        wps = [
            _wp("Museum A", "museum", 1),
            _wp("Cafe", "cafe", 2),
            _wp("Restaurant", "restaurant", 3),
            _wp("Museum B", "museum", 4),
            _wp("Museum C", "museum", 5),
            _wp("Dinner", "restaurant", 6, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_route_dining(route)
        cats = [w.category for w in result.days[0].waypoints]
        dining = {"restaurant", "cafe", "bar", "fast_food", "pub", "nightlife", "nightclub", "bakery", "food", "market"}
        for i in range(len(cats) - 1):
            assert not (cats[i] in dining and cats[i + 1] in dining), (
                f"Adjacent dining at positions {i} and {i+1}: {cats}"
            )

    def test_short_duration_normalised(self):
        wps = [
            _wp("Museum A", "museum", 1, duration=5),   # too short → should be bumped
            _wp("Lunch", "restaurant", 2, duration=60),
            _wp("Museum B", "museum", 3, duration=60),
            _wp("Dinner", "restaurant", 4, duration=60, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_route_dining(route)
        assert result.days[0].waypoints[0].estimated_duration_min >= 15

    def test_sightseeing_durations_bumped_when_total_below_420(self):
        # The bump is capped at 30 min per sight, so we verify that sightseeing
        # durations increase rather than asserting a specific total.
        wps = [
            _wp("Museum A", "museum", 1, duration=30),
            _wp("Lunch", "restaurant", 2, duration=60),
            _wp("Museum B", "museum", 3, duration=30),
            _wp("Sight C", "landmark", 4, duration=30),
            _wp("Dinner", "restaurant", 5, duration=60, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_route_dining(route)
        sight_durations = [
            w.estimated_duration_min
            for w in result.days[0].waypoints
            if w.category in ("museum", "landmark")
        ]
        # Each sight should have been bumped above its original 30 min
        assert all(d is not None and d > 30 for d in sight_durations)

    def test_order_renumbered_sequentially(self):
        wps = [
            _wp("Museum A", "museum", 5),
            _wp("Lunch", "restaurant", 10),
            _wp("Museum B", "museum", 15),
            _wp("Dinner", "restaurant", 20, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_route_dining(route)
        orders = [w.order for w in result.days[0].waypoints]
        assert orders == list(range(1, len(orders) + 1))


# ── _fix_dining_proximity ─────────────────────────────────────────────────────

class TestFixDiningProximity:
    # Sultanahmet area coords
    _SIGHT_LAT, _SIGHT_LON = 41.0086, 28.9802   # Hagia Sophia area
    _NEAR_REST_LAT, _NEAR_REST_LON = 41.0090, 28.9810   # ~80m away — in range
    _FAR_REST_LAT, _FAR_REST_LON = 41.0500, 29.0500     # ~6 km away — out of range

    def _tool_pois(self) -> list[dict]:
        return [
            {"name": "Near Restaurant", "category": "restaurant", "lat": self._NEAR_REST_LAT, "lon": self._NEAR_REST_LON},
            {"name": "Near Cafe", "category": "cafe", "lat": self._NEAR_REST_LAT, "lon": self._NEAR_REST_LON + 0.001},
        ]

    def test_in_range_dining_not_replaced(self):
        wps = [
            _wp("Hagia Sophia", "museum", 1, lat=self._SIGHT_LAT, lon=self._SIGHT_LON),
            _wp("Near Restaurant", "restaurant", 2, lat=self._NEAR_REST_LAT, lon=self._NEAR_REST_LON),
            _wp("Blue Mosque", "museum", 3, lat=self._SIGHT_LAT + 0.002, lon=self._SIGHT_LON + 0.002),
            _wp("Dinner", "restaurant", 4, lat=self._NEAR_REST_LAT, lon=self._NEAR_REST_LON, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_dining_proximity(route, self._tool_pois())
        names = [w.name for w in result.days[0].waypoints]
        assert "Near Restaurant" in names

    def test_out_of_range_dining_replaced(self):
        wps = [
            _wp("Hagia Sophia", "museum", 1, lat=self._SIGHT_LAT, lon=self._SIGHT_LON),
            _wp("Far Restaurant", "restaurant", 2, lat=self._FAR_REST_LAT, lon=self._FAR_REST_LON),
            _wp("Blue Mosque", "museum", 3, lat=self._SIGHT_LAT + 0.002, lon=self._SIGHT_LON + 0.002),
            _wp("Dinner", "restaurant", 4, lat=self._NEAR_REST_LAT, lon=self._NEAR_REST_LON, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_dining_proximity(route, self._tool_pois())
        names = [w.name for w in result.days[0].waypoints]
        assert "Far Restaurant" not in names
        assert "Near Restaurant" in names

    def test_empty_pool_leaves_route_unchanged(self):
        wps = [
            _wp("Museum", "museum", 1, lat=self._SIGHT_LAT, lon=self._SIGHT_LON),
            _wp("Restaurant", "restaurant", 2, lat=self._FAR_REST_LAT, lon=self._FAR_REST_LON),
        ]
        route = _route(_day(*wps))
        result = _fix_dining_proximity(route, [])
        # No pool → no replacement
        assert result.days[0].waypoints[1].name == "Restaurant"


# ── _fix_opening_hours ────────────────────────────────────────────────────────

class TestFixOpeningHours:
    def test_day_start_before_0830_clamped(self):
        wps = [_wp("Museum", "museum", 1, duration=60)]
        day = _day(*wps, start="07:00")
        route = _route(day)
        result = _fix_opening_hours(route)
        h, m = map(int, result.days[0].day_start_local.split(":"))
        assert (h, m) >= (8, 30)

    def test_museum_with_evening_time_slot_removed(self):
        wps = [
            _wp("Museum A", "museum", 1, lat=41.0, lon=28.9, duration=60, time_slot="morning"),
            _wp("Museum B", "museum", 2, lat=41.0, lon=28.9, duration=60, time_slot="evening"),
            _wp("Museum C", "museum", 3, lat=41.0, lon=28.9, duration=60, time_slot="morning"),
        ]
        route = _route(_day(*wps, start="09:00"))
        result = _fix_opening_hours(route)
        names = [w.name for w in result.days[0].waypoints]
        assert "Museum B" not in names

    def test_museum_arriving_after_1700_removed(self):
        # Fill the day until after 17:00 before the museum
        fillers = [_wp(f"Sight {i}", "landmark", i, duration=120) for i in range(1, 6)]
        late_museum = _wp("Late Museum", "museum", 6, duration=60, time_slot="afternoon")
        wps = fillers + [late_museum]
        route = _route(_day(*wps, start="09:00"))
        result = _fix_opening_hours(route)
        names = [w.name for w in result.days[0].waypoints]
        assert "Late Museum" not in names

    def test_non_museum_after_1700_kept(self):
        fillers = [_wp(f"Sight {i}", "landmark", i, duration=120) for i in range(1, 6)]
        late_restaurant = _wp("Late Dinner", "restaurant", 6, duration=60, time_slot="dinner")
        wps = fillers + [late_restaurant]
        route = _route(_day(*wps, start="09:00"))
        result = _fix_opening_hours(route)
        names = [w.name for w in result.days[0].waypoints]
        assert "Late Dinner" in names


# ── _fix_geographic_spread ────────────────────────────────────────────────────

class TestFixGeographicSpread:
    # Sultanahmet cluster ~41.008, 28.980
    # Distant outlier ~41.15, 28.98  (~16 km away)
    _BASE_LAT, _BASE_LON = 41.008, 28.980

    def _close(self, n: str, order: int, offset: float = 0.001) -> RouteWaypoint:
        return _wp(n, "museum", order, lat=self._BASE_LAT + offset, lon=self._BASE_LON + offset)

    def _far(self, n: str, order: int) -> RouteWaypoint:
        return _wp(n, "museum", order, lat=self._BASE_LAT + 0.14, lon=self._BASE_LON)

    def test_outlier_removed_when_enough_sights_remain(self):
        wps = [
            self._close("Museum A", 1),
            self._close("Museum B", 2, 0.002),
            self._close("Museum C", 3, 0.003),
            self._far("Distant Museum", 4),
        ]
        route = _route(_day(*wps))
        result = _fix_geographic_spread(route)
        names = [w.name for w in result.days[0].waypoints]
        assert "Distant Museum" not in names
        assert "Museum A" in names

    def test_outlier_kept_when_removal_leaves_too_few_sights(self):
        wps = [
            self._close("Museum A", 1),
            self._far("Distant Museum", 2),
        ]
        route = _route(_day(*wps))
        result = _fix_geographic_spread(route)
        # Only 2 sightseeing stops — removal would leave 1 → skip
        names = [w.name for w in result.days[0].waypoints]
        assert "Distant Museum" in names

    def test_dining_stops_never_removed(self):
        wps = [
            self._close("Museum A", 1),
            self._close("Museum B", 2, 0.002),
            self._close("Museum C", 3, 0.003),
            _wp("Far Restaurant", "restaurant", 4, lat=self._BASE_LAT + 0.14, lon=self._BASE_LON, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _fix_geographic_spread(route)
        names = [w.name for w in result.days[0].waypoints]
        assert "Far Restaurant" in names


# ── _optimize_route_order ─────────────────────────────────────────────────────

class TestOptimizeRouteOrder:
    def test_sightseeing_reordered_by_proximity(self):
        # Two close sights and one far sight interleaved; optimizer should group close ones
        wps = [
            _wp("Sight A", "museum", 1, lat=41.008, lon=28.980),
            _wp("Sight Far", "museum", 2, lat=41.100, lon=28.980),   # far from A
            _wp("Sight B", "museum", 3, lat=41.009, lon=28.981),     # close to A
            _wp("Dinner", "restaurant", 4, lat=41.008, lon=28.982, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _optimize_route_order(route)
        names = [w.name for w in result.days[0].waypoints]
        # Dinner must stay last (dining anchor)
        assert names[-1] == "Dinner"
        # A and B should be adjacent
        idx_a = names.index("Sight A")
        idx_b = names.index("Sight B")
        assert abs(idx_a - idx_b) == 1

    def test_dining_anchors_preserve_meal_rhythm(self):
        wps = [
            _wp("Morning Cafe", "cafe", 1, lat=41.008, lon=28.980, time_slot="morning"),
            _wp("Sight A", "museum", 2, lat=41.008, lon=28.981),
            _wp("Lunch", "restaurant", 3, lat=41.009, lon=28.980, time_slot="lunch"),
            _wp("Sight B", "museum", 4, lat=41.009, lon=28.982),
            _wp("Dinner", "restaurant", 5, lat=41.010, lon=28.980, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _optimize_route_order(route)
        cats = [w.category for w in result.days[0].waypoints]
        # Cafe must come before first restaurant (meal rhythm preserved)
        assert cats.index("cafe") < cats.index("restaurant")

    def test_order_field_reassigned_sequentially(self):
        wps = [
            _wp("Sight A", "museum", 1, lat=41.008, lon=28.980),
            _wp("Sight B", "museum", 2, lat=41.009, lon=28.981),
            _wp("Dinner", "restaurant", 3, lat=41.008, lon=28.982, time_slot="dinner"),
        ]
        route = _route(_day(*wps))
        result = _optimize_route_order(route)
        orders = [w.order for w in result.days[0].waypoints]
        assert orders == list(range(1, len(orders) + 1))


# ── _fix_duplicate_waypoints ──────────────────────────────────────────────────

class TestFixDuplicateWaypoints:
    def test_duplicate_across_days_removed(self):
        day1 = _day(
            _wp("Hagia Sophia", "museum", 1),
            _wp("Lunch", "restaurant", 2, time_slot="lunch"),
            _wp("Blue Mosque", "museum", 3),
            _wp("Dinner", "restaurant", 4, time_slot="dinner"),
            day_num=1,
        )
        # day2 has 3 sightseeing stops so removing the duplicate still leaves 2 (_MIN_SIGHTSEEING_PER_DAY)
        day2 = _day(
            _wp("Hagia Sophia", "museum", 1),   # duplicate
            _wp("Lunch2", "restaurant", 2, time_slot="lunch"),
            _wp("Topkapi Palace", "museum", 3),
            _wp("Galata Tower", "museum", 4),
            _wp("Dinner2", "restaurant", 5, time_slot="dinner"),
            day_num=2,
        )
        route = _route(day1, day2, total_days=2)
        result = _fix_duplicate_waypoints(route)
        day2_names = [w.name for w in result.days[1].waypoints]
        assert "Hagia Sophia" not in day2_names

    def test_first_occurrence_always_kept(self):
        day1 = _day(
            _wp("Topkapi Palace", "museum", 1),
            _wp("Lunch", "restaurant", 2, time_slot="lunch"),
            _wp("Grand Bazaar", "museum", 3),
            _wp("Dinner", "restaurant", 4, time_slot="dinner"),
            day_num=1,
        )
        day2 = _day(
            _wp("Topkapi Palace", "museum", 1),  # duplicate
            _wp("Lunch2", "restaurant", 2, time_slot="lunch"),
            _wp("Galata Tower", "museum", 3),
            _wp("Dinner2", "restaurant", 4, time_slot="dinner"),
            day_num=2,
        )
        route = _route(day1, day2, total_days=2)
        result = _fix_duplicate_waypoints(route)
        day1_names = [w.name for w in result.days[0].waypoints]
        assert "Topkapi Palace" in day1_names

    def test_removal_skipped_when_too_few_sights_remain(self):
        day1 = _day(
            _wp("Museum A", "museum", 1),
            _wp("Dinner", "restaurant", 2, time_slot="dinner"),
            day_num=1,
        )
        day2 = _day(
            _wp("Museum A", "museum", 1),  # duplicate — but removing leaves only 0 sights
            _wp("Dinner2", "restaurant", 2, time_slot="dinner"),
            day_num=2,
        )
        route = _route(day1, day2, total_days=2)
        result = _fix_duplicate_waypoints(route)
        # Removal skipped — day2 still has Museum A
        day2_names = [w.name for w in result.days[1].waypoints]
        assert "Museum A" in day2_names

    def test_order_renumbered_after_removal(self):
        day1 = _day(
            _wp("Museum A", "museum", 1),
            _wp("Lunch", "restaurant", 2, time_slot="lunch"),
            _wp("Museum B", "museum", 3),
            _wp("Dinner", "restaurant", 4, time_slot="dinner"),
            day_num=1,
        )
        day2 = _day(
            _wp("Museum A", "museum", 1),   # duplicate → removed
            _wp("Lunch2", "restaurant", 2, time_slot="lunch"),
            _wp("Museum C", "museum", 3),
            _wp("Museum D", "museum", 4),
            _wp("Dinner2", "restaurant", 5, time_slot="dinner"),
            day_num=2,
        )
        route = _route(day1, day2, total_days=2)
        result = _fix_duplicate_waypoints(route)
        orders = [w.order for w in result.days[1].waypoints]
        assert orders == list(range(1, len(orders) + 1))


# ── _is_trivial_message ───────────────────────────────────────────────────────

class TestIsTrivialMessage:
    @pytest.mark.parametrize("msg", [
        "Teşekkürler",
        "tamam",
        "Harika!",
        "thanks",
        "ok",
        "Perfect!",
        "got it",
        "süper",
        "merci",
        "grazie",
    ])
    def test_trivial_messages_detected(self, msg: str):
        assert _is_trivial_message(msg) is True

    @pytest.mark.parametrize("msg", [
        "3 günlük İstanbul turu istiyorum",
        "Deniz ürünlerine alerjim var",
        "Vejetaryenim, bunu göz önünde bulundur",
        "Harika! Peki müzeleri seviyor musun?",   # > 25 chars
        "Teşekkürler, ama bir sorum var",           # > 25 chars
    ])
    def test_non_trivial_messages_not_flagged(self, msg: str):
        assert _is_trivial_message(msg) is False

    def test_empty_string_is_not_trivial(self):
        # Empty string returns False — it's blocked upstream by moderation/validation,
        # not by the trivial-message check.
        assert _is_trivial_message("") is False

    def test_long_trivial_phrase_not_flagged(self):
        # Matches the pattern but exceeds _TRIVIAL_MAX_CHARS
        assert _is_trivial_message("teşekkürler çok güzel oldu harika") is False
