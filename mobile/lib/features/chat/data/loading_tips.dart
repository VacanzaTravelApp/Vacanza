/// Travel tips shown during AI loading — ported from web `loadingTips.js`.
///
/// Each tip has an optional [city] (null = generic), a [category], and the
/// [tip] text itself. [getTipsForCity] returns a shuffled pool that prioritises
/// city-specific tips when the user's message mentions a known city.
class TravelTip {
  final String? city;
  final String category;
  final String tip;

  const TravelTip({this.city, required this.category, required this.tip});
}

const _tips = <TravelTip>[
  // ── Generic ──
  TravelTip(category: 'safety', tip: "Always carry a physical business card of your hotel; it's a lifesaver if your phone dies and you need to tell a taxi where to go."),
  TravelTip(category: 'budget', tip: 'Withdraw cash from bank-affiliated ATMs rather than generic ones in kiosks to avoid predatory exchange rates.'),
  TravelTip(category: 'transport', tip: "Download offline maps for the entire city area on Google Maps before leaving your hotel's Wi-Fi."),
  TravelTip(category: 'local_tip', tip: "Learn how to say 'The check, please' and 'Thank you' in the local language; it changes the service quality instantly."),
  TravelTip(category: 'packing', tip: 'Pack a multi-plug power strip so you only need one travel adapter to charge all your devices at once.'),
  TravelTip(category: 'food', tip: "If a restaurant has a menu with photos of every dish and a person calling you in, it's usually a tourist trap."),
  TravelTip(category: 'photography', tip: 'Wake up at sunrise for the best light and to get photos of famous landmarks without the crowds.'),
  TravelTip(category: 'culture', tip: 'Always check the local holiday calendar before booking; many shops and museums might be closed unexpectedly.'),
  TravelTip(category: 'safety', tip: "Split your cash and credit cards into two different bags; if one is lost, you aren't stranded."),
  TravelTip(category: 'accommodation', tip: "Check for a 'luggage storage' option in your hotel description if you have a late flight after checkout."),
  TravelTip(category: 'timing', tip: 'Pre-book tickets for major attractions at least 2 weeks in advance to avoid 3-hour long queues.'),
  TravelTip(category: 'family', tip: 'Always carry a portable power bank; using navigation apps drains your battery faster than you think.'),
  TravelTip(category: 'shopping', tip: 'Keep your receipts for expensive items; you may be eligible for a VAT tax refund at the airport.'),
  TravelTip(category: 'nature', tip: "Check the local 'stinging' or 'poisonous' wildlife if you plan on hiking in remote areas."),
  TravelTip(category: 'weather', tip: 'Carry a lightweight, foldable raincoat even if the forecast says sun; mountain and coastal weather is unpredictable.'),
  TravelTip(category: 'transport', tip: 'Public transport is almost always faster than taxis in major cities during rush hour.'),
  TravelTip(category: 'local_tip', tip: "Look for where the local students or office workers eat lunch; that's where the best value food is."),
  TravelTip(category: 'culture', tip: 'Research the local dress code for religious sites to avoid being turned away at the entrance.'),
  TravelTip(category: 'budget', tip: 'Lunch menus are often 30-50% cheaper than dinner menus for the exact same food.'),
  TravelTip(category: 'health', tip: 'Check if tap water is drinkable in your destination; if not, even ice in drinks can be a risk.'),
  TravelTip(category: 'communication', tip: 'Take a screenshot of your flight and hotel confirmation QR codes in case you have no signal at the counter.'),
  TravelTip(category: 'hidden_gem', tip: 'Walk at least three blocks away from the main square to find authentic, locally-owned shops.'),
  TravelTip(category: 'safety', tip: 'Wear your backpack on your front in extremely crowded subways or markets to prevent pickpocketing.'),
  TravelTip(category: 'transport', tip: "Check if there is a 'Day Pass' for public transport; it usually pays for itself in just three trips."),
  TravelTip(category: 'food', tip: 'Try the street food that has the longest line of locals; a high turnover means the food is fresh.'),
  TravelTip(category: 'culture', tip: "Don't use your left hand for eating or greeting in certain Middle Eastern and Asian cultures."),
  TravelTip(category: 'photography', tip: "Turn off your flash in museums and churches; it's usually banned and ruins the atmosphere for others."),
  TravelTip(category: 'budget', tip: 'Free walking tours are a great way to orient yourself, but remember to tip the guide at the end.'),
  TravelTip(category: 'safety', tip: 'Note down the local emergency number (like 911 or 112) as soon as you land.'),
  TravelTip(category: 'packing', tip: 'Roll your clothes instead of folding them to save space and minimize wrinkles in your suitcase.'),

  // ── Istanbul ──
  TravelTip(city: 'Istanbul', category: 'transport', tip: "Use the ferries to cross between continents; it's the cheapest 'mini-cruise' with the best views of the city."),
  TravelTip(city: 'Istanbul', category: 'food', tip: "Skip the hotel breakfast once and find a 'Van Kahvaltı Evi' for a massive, traditional Turkish breakfast spread."),
  TravelTip(city: 'Istanbul', category: 'hidden_gem', tip: 'The Kuzguncuk neighborhood on the Asian side offers a peaceful, nostalgic look at old Istanbul away from the noise.'),
  TravelTip(city: 'Istanbul', category: 'shopping', tip: 'In the Grand Bazaar, the first price is never the final price. Aim to pay about 40% less than the starting offer.'),
  TravelTip(city: 'Istanbul', category: 'culture', tip: "Mosques are closed to visitors during prayer times; check the 'Ezan' times and visit in between."),
  TravelTip(city: 'Istanbul', category: 'local_tip', tip: 'Get an Istanbulkart at the airport or any metro station; you can use it for buses, metros, ferries, and even public toilets.'),
  TravelTip(city: 'Istanbul', category: 'timing', tip: 'Visit the Basilica Cistern right when it opens or an hour before closing to avoid the massive tour groups.'),
  TravelTip(city: 'Istanbul', category: 'nightlife', tip: "Kadikoy's 'Bar Street' on the Asian side is much more relaxed and local than the overly touristy Istiklal Street."),
  TravelTip(city: 'Istanbul', category: 'photography', tip: 'The rooftop of Galata Konak Cafe offers a 360-degree view of the Galata Tower and the Golden Horn without an entry fee.'),
  TravelTip(city: 'Istanbul', category: 'safety', tip: "If a stranger invites you to a 'special bar' for a drink, it's a common scam. Politely decline and walk away."),
  TravelTip(city: 'Istanbul', category: 'weather', tip: 'Istanbul is windier than you expect; even in summer, a light jacket is useful for ferry rides after sunset.'),
  TravelTip(city: 'Istanbul', category: 'family', tip: "Miniaturk is a great spot for kids to see tiny versions of all Turkey's landmarks in one park."),
  TravelTip(city: 'Istanbul', category: 'accommodation', tip: 'Stay in Sirkeci or Karakoy rather than Sultanahmet to be close to history but with better food and transport options.'),
  TravelTip(city: 'Istanbul', category: 'food', tip: "Try 'Balık Ekmek' (fish sandwich) in Eminonu, but look for the boats where the locals are queuing."),
  TravelTip(city: 'Istanbul', category: 'budget', tip: 'Use the Marmaray train to get from Europe to Asia in 4 minutes for just a few liras.'),

  // ── Paris ──
  TravelTip(city: 'Paris', category: 'food', tip: "Order a 'carafe d'eau' at restaurants; it's free tap water, whereas 'eau minérale' can cost 7 Euros."),
  TravelTip(city: 'Paris', category: 'transport', tip: "Don't buy single metro tickets; get a 'Navigo Easy' card and load it with a 10-journey 'carnet' to save money."),
  TravelTip(city: 'Paris', category: 'culture', tip: 'The Louvre is closed on Tuesdays. Plan your visit for Wednesday or Friday evenings when it stays open late and is less crowded.'),
  TravelTip(city: 'Paris', category: 'local_tip', tip: "Always greet shopkeepers with a 'Bonjour' before asking a question; it is considered very rude to skip this."),
  TravelTip(city: 'Paris', category: 'photography', tip: 'For the best photo of the Eiffel Tower, go to the Trocadéro platform at sunrise.'),
  TravelTip(city: 'Paris', category: 'hidden_gem', tip: 'The Promenade Plantée is an elevated park built on an old railway line, offering a quiet green escape above the streets.'),
  TravelTip(city: 'Paris', category: 'budget', tip: 'Many museums, including the Louvre, offer free entry on the first Sunday of the month (seasonal, check dates).'),
  TravelTip(city: 'Paris', category: 'safety', tip: "Beware of the 'string scam' near Sacré-Cœur; don't let anyone tie anything around your wrist."),
  TravelTip(city: 'Paris', category: 'timing', tip: 'Climb the Arc de Triomphe just before sunset to see the city lights and the Eiffel Tower sparkling.'),
  TravelTip(city: 'Paris', category: 'nightlife', tip: 'Skip the expensive Moulin Rouge and head to the bars in Oberkampf for a more authentic Parisian night out.'),
  TravelTip(city: 'Paris', category: 'family', tip: 'The Jardin du Luxembourg has a great traditional puppet theater (Guignol) that kids love.'),
  TravelTip(city: 'Paris', category: 'shopping', tip: "Visit the 'Bouquinistes' along the Seine for vintage posters, old books, and unique souvenirs."),
  TravelTip(city: 'Paris', category: 'nature', tip: 'Rent a small boat in the Bois de Boulogne for a peaceful afternoon on the lake.'),
  TravelTip(city: 'Paris', category: 'accommodation', tip: 'Stay in the 11th or 12th Arrondissement for a more local vibe and much cheaper hotel rates than the 1st.'),
  TravelTip(city: 'Paris', category: 'local_tip', tip: "A 'boulangerie' with a 'Grand Prix de la Baguette' sticker means they won the award for the best bread in the city."),

  // ── Tokyo ──
  TravelTip(city: 'Tokyo', category: 'local_tip', tip: 'There are almost no public trash cans in Tokyo; carry a small plastic bag to store your rubbish until you return to your hotel.'),
  TravelTip(city: 'Tokyo', category: 'transport', tip: 'Get a Suica or Pasmo card immediately; they work for all trains, buses, and even for paying at vending machines and convenience stores.'),
  TravelTip(city: 'Tokyo', category: 'food', tip: 'Department store basements (Depachika) offer incredible high-quality food and are perfect for a gourmet picnic.'),
  TravelTip(city: 'Tokyo', category: 'culture', tip: "Don't eat or drink while walking; it's considered impolite in Japanese culture. Stand near the vending machine instead."),
  TravelTip(city: 'Tokyo', category: 'photography', tip: 'The Shibuya Sky observatory offers the best view of the famous scramble crossing from above.'),
  TravelTip(city: 'Tokyo', category: 'hidden_gem', tip: "Yanaka Ginza is a 'shitamachi' (old town) area that survived the wars, giving you a glimpse of 1950s Tokyo."),
  TravelTip(city: 'Tokyo', category: 'budget', tip: 'For a free panoramic view of the city, visit the Tokyo Metropolitan Government Building in Shinjuku.'),
  TravelTip(city: 'Tokyo', category: 'safety', tip: "Tokyo is extremely safe, but in nightlife areas like Roppongi, avoid 'touts' promising cheap drinks or girls."),
  TravelTip(city: 'Tokyo', category: 'timing', tip: "Avoid the subways between 8:00 AM and 9:00 AM unless you want to experience the extreme 'shove' of rush hour."),
  TravelTip(city: 'Tokyo', category: 'nightlife', tip: "Visit Golden Gai in Shinjuku for tiny, 6-seat themed bars, but check the 'cover charge' posted on the door first."),
  TravelTip(city: 'Tokyo', category: 'shopping', tip: 'Don Quijote (Donki) is a massive discount store perfect for picking up unique Kit-Kat flavors and souvenirs.'),
  TravelTip(city: 'Tokyo', category: 'family', tip: 'The Ghibli Museum is magical but tickets must be booked exactly one month in advance online; they sell out in minutes.'),
  TravelTip(city: 'Tokyo', category: 'nature', tip: "Shinjuku Gyoen National Garden is a massive oasis in the city; it's worth the small entry fee for the silence."),
  TravelTip(city: 'Tokyo', category: 'accommodation', tip: 'Hotel rooms in Tokyo are notoriously small; if you have large suitcases, check the room square footage before booking.'),
  TravelTip(city: 'Tokyo', category: 'food', tip: "Ordering at ramen shops is usually done via a vending machine at the entrance. Put your money in first, then push the button."),

  // ── New York ──
  TravelTip(city: 'New York', category: 'transport', tip: 'Never take a car/taxi to cross Midtown during the day; the subway is always faster and cheaper.'),
  TravelTip(city: 'New York', category: 'food', tip: 'A \$1.50 slice of pizza is a New York staple. Look for the shops with high turnover for the freshest crust.'),
  TravelTip(city: 'New York', category: 'photography', tip: 'Walk across the Brooklyn Bridge towards Brooklyn at sunset for the best view of the Manhattan skyline.'),
  TravelTip(city: 'New York', category: 'budget', tip: 'The Staten Island Ferry is completely free and passes right by the Statue of Liberty.'),
  TravelTip(city: 'New York', category: 'local_tip', tip: 'Walk on the right side of the sidewalk and never stop suddenly in the middle; New Yorkers are always in a rush.'),
  TravelTip(city: 'New York', category: 'hidden_gem', tip: 'Visit The Cloisters in Upper Manhattan for a medieval European monastery experience right in the city.'),
  TravelTip(city: 'New York', category: 'safety', tip: "Don't take photos with the costumed characters in Times Square unless you are prepared to pay them \$5-10."),
  TravelTip(city: 'New York', category: 'timing', tip: 'Mid-week matinee Broadway shows are often cheaper and easier to get tickets for via the TKTS booth.'),
  TravelTip(city: 'New York', category: 'nightlife', tip: "Speakeasies are big here; look for 'Please Don't Tell', hidden behind a phone booth in a hot dog shop."),
  TravelTip(city: 'New York', category: 'shopping', tip: "Century 21 is back! It's the best place for designer labels at massive discounts near the World Trade Center."),
  TravelTip(city: 'New York', category: 'family', tip: 'The Central Park Zoo is small and manageable, perfect for a 2-hour activity with younger children.'),
  TravelTip(city: 'New York', category: 'nature', tip: 'Walk the High Line, an elevated park on an old rail line, but go on a weekday morning to avoid the crowds.'),
  TravelTip(city: 'New York', category: 'accommodation', tip: "Stay in Long Island City (Queens); it's one subway stop from Manhattan and half the price."),
  TravelTip(city: 'New York', category: 'culture', tip: 'Tipping 20% at restaurants is standard in NYC; anything less is considered a sign of poor service.'),
  TravelTip(city: 'New York', category: 'local_tip', tip: "Download the 'Curb' or 'Revel' app for alternatives to Uber/Lyft which can be very expensive here."),

  // ── Cappadocia ──
  TravelTip(city: 'Cappadocia', category: 'photography', tip: "The balloons fly at sunrise. Be at a 'Balloon Viewpoint' 30 minutes before dawn for the best lighting."),
  TravelTip(city: 'Cappadocia', category: 'weather', tip: 'Even in July, it can be very cold at sunrise when you go for a balloon flight. Bring a windbreaker.'),
  TravelTip(city: 'Cappadocia', category: 'transport', tip: 'Renting a car or a scooter is highly recommended as the valleys and underground cities are far apart.'),
  TravelTip(city: 'Cappadocia', category: 'hidden_gem', tip: 'Skip the crowded Goreme Open Air Museum and visit the Zelve Open Air Museum for a more rugged, authentic experience.'),
  TravelTip(city: 'Cappadocia', category: 'accommodation', tip: 'Stay in a cave hotel in Cavusin or Ortahisar for a more traditional and quiet stay than Goreme.'),
  TravelTip(city: 'Cappadocia', category: 'food', tip: "Try the 'Testi Kebab' (pottery kebab). You have to crack the clay pot yourself to get the meat out!"),
  TravelTip(city: 'Cappadocia', category: 'nature', tip: "The Ihlara Valley hike is beautiful but it's a one-way path. Make sure your tour or transport picks you up at the end."),
  TravelTip(city: 'Cappadocia', category: 'local_tip', tip: "If your balloon flight is canceled due to wind, it will likely be moved to the next day. Don't book it on your last morning."),
  TravelTip(city: 'Cappadocia', category: 'shopping', tip: 'Avanos is the center of pottery. Most workshops offer a free trial where you can try the pottery wheel yourself.'),
  TravelTip(city: 'Cappadocia', category: 'culture', tip: 'The Whirling Dervish ceremony at the Saruhan Caravanserai is an atmospheric, spiritual experience in a 13th-century building.'),
  TravelTip(city: 'Cappadocia', category: 'safety', tip: "When hiking in the valleys (like Rose Valley), the paths aren't well marked. Use an app like AllTrails to stay on track."),
  TravelTip(city: 'Cappadocia', category: 'family', tip: 'Kaymakli Underground City is easier to navigate with kids than Derinkuyu, which has much tighter tunnels.'),
  TravelTip(city: 'Cappadocia', category: 'budget', tip: "The 'Museum Pass Turkey' covers almost all sites here and will save you money if you visit more than three attractions."),
  TravelTip(city: 'Cappadocia', category: 'photography', tip: 'Pigeon Valley offers the best sunset view overlooking Uchisar Castle.'),
  TravelTip(city: 'Cappadocia', category: 'local_tip', tip: 'Wear sturdy shoes with good grip; the volcanic tuff rock is very slippery even when dry.'),
];

const _cityAliases = <String, String>{
  'istanbul': 'Istanbul',
  'paris': 'Paris',
  'tokyo': 'Tokyo',
  'new york': 'New York',
  'nyc': 'New York',
  'cappadocia': 'Cappadocia',
  'kapadokya': 'Cappadocia',
  'antalya': 'Antalya',
  'rome': 'Rome',
  'roma': 'Rome',
  'london': 'London',
  'barcelona': 'Barcelona',
};

/// Returns a shuffled pool of travel tips, prioritising city-specific ones
/// when the user's text mentions a known city keyword.
///
/// Mirrors web `getTipsForCity(cityHint)`.
List<TravelTip> getTipsForCity(String cityHint) {
  final lower = cityHint.toLowerCase();

  String? cityKey;
  for (final entry in _cityAliases.entries) {
    if (lower.contains(entry.key)) {
      cityKey = entry.value;
      break;
    }
  }

  final cityTips =
      cityKey != null ? _tips.where((t) => t.city == cityKey).toList() : <TravelTip>[];
  final generalTips = _tips.where((t) => t.city == null).toList();

  final pool = cityTips.isNotEmpty ? [...cityTips, ...generalTips] : generalTips;
  pool.shuffle();
  return pool;
}
