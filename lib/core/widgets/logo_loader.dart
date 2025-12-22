import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoLoader extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? loaderColor;

  const LogoLoader({
    super.key,
    this.message,
    this.size,
    this.loaderColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final loaderSize = size ?? (screenSize.width < 600 ? 100.0 : 120.0);
    final logoSize = loaderSize * 0.85;
    final strokeWidth = loaderSize * 0.08;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: loaderSize,
            height: loaderSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: loaderSize,
                  height: loaderSize,
                  child: CircularProgressIndicator(
                    strokeWidth: strokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      loaderColor ?? Colors.blue.shade400,
                    ),
                  ),
                ),
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

