/// Represents a quote displayed on the minimalist SnapDog splash screen.
class SplashQuote {
  final String text;
  final String? attribution;

  const SplashQuote({
    required this.text,
    this.attribution,
  });
}

/// Curated collection of calm, motivational, and playful quotes for SnapDog startup.
const List<SplashQuote> splashQuotes = [
  SplashQuote(text: 'Play a little. Smile a lot.'),
  SplashQuote(text: 'A little puzzle can brighten your day.'),
  SplashQuote(text: 'Stay pawsitive. Keep playing.'),
  SplashQuote(text: 'Small challenges, happy moments.'),
  SplashQuote(text: 'Take a breath. Find your next move.'),
  SplashQuote(text: 'Every puzzle is a fresh start.'),
];
