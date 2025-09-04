// lib/core/widgets/star_rating_input.dart

import 'package:flutter/material.dart';

/// A widget for selecting a rating from 1 to 5 stars.
///
/// This is a stateful widget that allows user interaction to select a rating.
/// It calls the [onRatingChanged] callback whenever the rating is updated.
class StarRatingInput extends StatefulWidget {
  /// Callback function that is called when the rating changes.
  final void Function(double rating) onRatingChanged;

  const StarRatingInput({
    super.key,
    required this.onRatingChanged,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  // The current selected rating. Initialized to 0, meaning no stars are selected.
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          // The icon changes based on whether it's selected or not.
          icon: Icon(
            index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            // When a star is pressed, update the state and call the callback.
            setState(() {
              _rating = index + 1.0;
              widget.onRatingChanged(_rating);
            });
          },
        );
      }),
    );
  }
}
