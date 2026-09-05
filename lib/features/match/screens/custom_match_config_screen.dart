import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/match_format.dart';

class CustomMatchConfigScreen extends StatefulWidget {
  const CustomMatchConfigScreen({super.key});

  @override
  State<CustomMatchConfigScreen> createState() =>
      _CustomMatchConfigScreenState();
}

class _CustomMatchConfigScreenState extends State<CustomMatchConfigScreen> {
  int _value = 2;
  String? _errorText;

  static const int _min = 2;
  static const int _max = 99;

  void _increment() {
    setState(() {
      if (_value < _max) {
        _value++;
        _errorText = null;
      }
    });
  }

  void _decrement() {
    setState(() {
      if (_value > _min) {
        _value--;
        _errorText = null;
      }
    });
  }

  void _onDigit(int digit) {
    setState(() {
      final currentText = _value.toString();
      if (currentText == '0') {
        _value = digit;
      } else if (int.parse(currentText + digit.toString()) <= _max) {
        _value = int.parse(currentText + digit.toString());
      }
      _errorText = null;
    });
  }

  void _onBackspace() {
    setState(() {
      final currentText = _value.toString();
      if (currentText.length > 1) {
        _value = int.parse(currentText.substring(0, currentText.length - 1));
      } else {
        _value = _min;
      }
    });
  }

  void _onDelete() {
    setState(() {
      _value = _min;
    });
  }

  void _onConfirm() {
    final error = MatchFormatConfig.validateCustomWins(_value);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    Navigator.of(context).pop(MatchFormatConfig.custom(_value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Expanded(child: _buildStepperCard()),
            const SizedBox(height: 32),
            _buildNumberPad(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'CUSTOM MATCH',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepperCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19.5),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.blue.withValues(alpha: 0.5),
                AppColors.purple.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'WINS REQUIRED',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepperButton(
                      icon: Icons.remove,
                      onTap: _decrement,
                      enabled: _value > _min,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '$_value',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildStepperButton(
                      icon: Icons.add,
                      onTap: _increment,
                      enabled: _value < _max,
                    ),
                  ],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19.5),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF03BBE8),
                          Color(0xFFC631E0),
                        ],
                        stops: [0.2, 0.8],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19.5),
                        ),
                      ),
                      child: const Text(
                        'CONFIRM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? Colors.white10 : Colors.white10,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.white24 : Colors.white10,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.primaryText : Colors.white24,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildNumberPadRow([1, 2, 3]),
          const SizedBox(height: 8),
          _buildNumberPadRow([4, 5, 6]),
          const SizedBox(height: 8),
          _buildNumberPadRow([7, 8, 9]),
          const SizedBox(height: 8),
          _buildBottomNumberPadRow(),
        ],
      ),
    );
  }

  Widget _buildNumberPadRow(List<int> digits) {
    return Row(
      children: digits.map((digit) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNumberPadButton(
              label: '$digit',
              onTap: () => _onDigit(digit),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNumberPadRow() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNumberPadButton(
              label: 'BACK',
              onTap: _onBackspace,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNumberPadButton(
              label: '0',
              onTap: () => _onDigit(0),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNumberPadButton(
              label: 'DEL',
              onTap: _onDelete,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberPadButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
