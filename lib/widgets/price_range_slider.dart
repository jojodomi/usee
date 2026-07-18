import 'package:flutter/material.dart';

class PriceRangeSlider extends StatefulWidget {
  final RangeValues values;
  final Function(RangeValues) onChanged;
  final double min;
  final double max;

  const PriceRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1000000,
  });

  @override
  State<PriceRangeSlider> createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends State<PriceRangeSlider> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = widget.values;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RangeSlider(
          values: _values,
          min: widget.min,
          max: widget.max,
          divisions: 100,
          labels: RangeLabels(
            '${_values.start.toStringAsFixed(0)} FCFA',
            '${_values.end.toStringAsFixed(0)} FCFA',
          ),
          onChanged: (values) {
            setState(() {
              _values = values;
            });
            widget.onChanged(values);
          },
          activeColor: Colors.green,
          inactiveColor: Colors.grey[300],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Min: ${_values.start.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Max: ${_values.end.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}