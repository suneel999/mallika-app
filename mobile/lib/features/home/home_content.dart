import 'package:flutter/material.dart';

// Emergency number and the campus line come from the approved home design.
// The grid is always two square cards wide.

enum HomeTap { book, services, call, map }

class ClinicalCard {
  const ClinicalCard({
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
    required this.tint,
    required this.tap,
  });

  final String title;
  final String caption;
  final IconData icon;

  /// Colour of the icon tile and the faint icon in the corner.
  final Color color;

  /// Pale colour the card fades into.
  final Color tint;
  final HomeTap tap;
}

const clinicalCards = <ClinicalCard>[
  ClinicalCard(
    title: 'Book Consultation',
    caption: 'Request a visit',
    icon: Icons.medical_services_rounded,
    color: Color(0xFF0C1B5B),
    tint: Color(0xFFDDE6FB),
    tap: HomeTap.book,
  ),
  ClinicalCard(
    title: '4D Echo',
    caption: 'Heart ultrasound',
    icon: Icons.monitor_heart_rounded,
    color: Color(0xFF005DB7),
    tint: Color(0xFFD9ECFF),
    tap: HomeTap.services,
  ),
  ClinicalCard(
    title: 'CT Calcium',
    caption: 'Calcium score scan',
    icon: Icons.blur_circular_rounded,
    color: Color(0xFF0E7C86),
    tint: Color(0xFFD7F3F2),
    tap: HomeTap.services,
  ),
  ClinicalCard(
    title: 'CT Angio',
    caption: 'Coronary CT scan',
    icon: Icons.favorite_rounded,
    color: Color(0xFFC2255C),
    tint: Color(0xFFFDE2EC),
    tap: HomeTap.services,
  ),
  ClinicalCard(
    title: 'Lab Tests',
    caption: 'Blood and other tests',
    icon: Icons.science_rounded,
    color: Color(0xFF6D3FC8),
    tint: Color(0xFFEBE3FD),
    tap: HomeTap.services,
  ),
  ClinicalCard(
    title: 'Ambulance',
    caption: 'Call 108',
    icon: Icons.emergency_rounded,
    color: Color(0xFFD92D20),
    tint: Color(0xFFFFE3E0),
    tap: HomeTap.call,
  ),
];

const emergencyPhoneUri = 'tel:108';

const hospitalMapsUri = 'https://maps.app.goo.gl/UGKJ3hgTcLZqGY4V9';
