/// [nowMinutes], [nightStartMinutes], [nightEndMinutes] gün içi 0–1439 dakika.
///
/// [nightStartMinutes] > [nightEndMinutes] ise pencere gece yarısını keser
/// (örn. 20:00 → 07:00: gece 20:00–24:00 ve 00:00–07:00).
bool isNightMinutes(
  int nowMinutes,
  int nightStartMinutes,
  int nightEndMinutes,
) {
  assert(nowMinutes >= 0 && nowMinutes < 1440);
  assert(nightStartMinutes >= 0 && nightStartMinutes < 1440);
  assert(nightEndMinutes >= 0 && nightEndMinutes < 1440);

  if (nightStartMinutes > nightEndMinutes) {
    return nowMinutes >= nightStartMinutes || nowMinutes < nightEndMinutes;
  }
  return nowMinutes >= nightStartMinutes && nowMinutes < nightEndMinutes;
}
