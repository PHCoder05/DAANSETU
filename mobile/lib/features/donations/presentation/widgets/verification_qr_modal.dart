import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../config/theme.dart';

class VerificationQrModal extends StatelessWidget {
  final String qrCode;
  final String type; // 'pickup' or 'delivery'
  final String donationTitle;

  const VerificationQrModal({
    super.key,
    required this.qrCode,
    required this.type,
    required this.donationTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = type == 'pickup';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPickup ? 'Pickup Verification' : 'Delivery Verification',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show this QR code to the volunteer to ${isPickup ? 'confirm pickup' : 'confirm delivery'} of "$donationTitle"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: QrImageView(
              data: qrCode,
              version: QrVersions.auto,
              size: 200.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.primaryRed,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppTheme.black,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Verification Code: $qrCode',
            style: const TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.offWhite,
                foregroundColor: AppTheme.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
