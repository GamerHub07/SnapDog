import 'package:flutter/material.dart';
import '../../../shared/widgets/dog_avatar.dart';
import '../../game/models/dog_breed.dart';

/// Decorative horizontal row of consistent 3D clay-style dog-face illustrations
/// for the SnapDog home screen.
///
/// Features:
/// - Displays consistent 3D clay dog faces (head/face only, not full body)
/// - Each breed is visually distinct (Beagle, Corgi, Golden Retriever, Husky, Labrador, Pug)
/// - Circular backgrounds with subtle borders and soft shadows
/// - Highly responsive across screen sizes
class HomeDogFaceRow extends StatelessWidget {
  const HomeDogFaceRow({super.key});

  @override
  Widget build(BuildContext context) {
    const breeds = DogBreed.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        // Dynamically compute avatar diameter between 38 and 46 px
        final double itemSize = ((maxWidth - 60) / breeds.length).clamp(36.0, 46.0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < breeds.length; i++) ...[
                if (i > 0) SizedBox(width: (maxWidth < 360 ? 6.0 : 10.0)),
                _DogFaceBubble(
                  breed: breeds[i],
                  size: itemSize,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DogFaceBubble extends StatelessWidget {
  final DogBreed breed;
  final double size;

  const _DogFaceBubble({
    required this.breed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return DogAvatar.circularBadge(
      breed: breed,
      size: size,
    );
  }
}
