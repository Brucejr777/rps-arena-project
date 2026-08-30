import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/match_format.dart';

class MatchFormatSelectScreen extends StatelessWidget {
  const MatchFormatSelectScreen({super.key});

  static const _options = <(String, MatchFormat)>[
    ('BEST OF 3', MatchFormat.bestOf3),
    ('BEST OF 5', MatchFormat.bestOf5),
    ('BEST OF 7', MatchFormat.bestOf7),
    ('BEST OF 9', MatchFormat.bestOf9),
    ('CUSTOM', MatchFormat.custom),
    ('UNLIMITED', MatchFormat.unlimited),
  ];

  MatchFormatConfig _configFor(MatchFormat format) {
    switch (format) {
      case MatchFormat.bestOf3:
        return MatchFormatConfig.bestOf3();
      case MatchFormat.bestOf5:
        return MatchFormatConfig.bestOf5();
      case MatchFormat.bestOf7:
        return MatchFormatConfig.bestOf7();
      case MatchFormat.bestOf9:
        return MatchFormatConfig.bestOf9();
      case MatchFormat.custom:
        // CUSTOM needs its own config screen (T25) to pick winsRequired.
        // Selecting it here just signals "go configure custom" — the
        // caller distinguishes this by checking format == custom.
        return MatchFormatConfig.custom(0); // placeholder, T25 sets the real value
      case MatchFormat.unlimited:
        return MatchFormatConfig.unlimited();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'MATCH LENGTH',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final (label, format) = _options[index];
                    return GestureDetector(
                      onTap: () {
                        // For CUSTOM, the caller (T25 flow) should route to
                        // CustomMatchConfigScreen instead of popping directly.
                        // For now, we pop back with the chosen format/config.
                        Navigator.of(context).pop(_configFor(format));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}