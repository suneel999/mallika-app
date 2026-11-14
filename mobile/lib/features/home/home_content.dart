import 'package:flutter/material.dart';

// The grid is always two cards wide.

enum HomeTap { book, service, soon, call, map }

class ClinicalCard {
  const ClinicalCard({
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
    required this.tap,
    this.photo,
    this.serviceName,
  });

  final String title;
  final String caption;
  final IconData icon;

  /// Colour of the icon tile.
  final Color color;

  final HomeTap tap;

  /// A face shown beside the icon. Only the consultation card has one.
  final String? photo;

  /// The published service this card requests, by its name on the server.
  final String? serviceName;
}

/// The consultation doctor, given by the hospital. The request screen reads
/// the published doctor from the server; this is what the home card shows.
const consultationDoctorName = 'Dr. J Mahesh Babu';
const consultationDoctorPhoto = 'assets/home/doctor_consultation.jpg';

const clinicalCards = <ClinicalCard>[
  ClinicalCard(
    title: 'Book Consultation',
    caption: consultationDoctorName,
    icon: Icons.medical_services_rounded,
    color: Color(0xFF0C1B5B),
    tap: HomeTap.book,
    photo: consultationDoctorPhoto,
  ),
  ClinicalCard(
    title: '4D Echo',
    caption: 'Heart ultrasound',
    icon: Icons.monitor_heart_rounded,
    color: Color(0xFF005DB7),
    tap: HomeTap.service,
    serviceName: '4D Echo',
  ),
  ClinicalCard(
    title: 'CT Calcium',
    caption: 'Calcium score scan',
    icon: Icons.blur_circular_rounded,
    color: Color(0xFF0E7C86),
    tap: HomeTap.service,
    serviceName: 'CT Calcium',
  ),
  ClinicalCard(
    title: 'CT Angio',
    caption: 'Coronary CT scan',
    icon: Icons.favorite_rounded,
    color: Color(0xFFC2255C),
    tap: HomeTap.service,
    serviceName: 'CT Angio',
  ),
  ClinicalCard(
    title: 'Lab Tests',
    caption: 'Blood and other tests',
    icon: Icons.science_rounded,
    color: Color(0xFF6D3FC8),
    tap: HomeTap.soon,
  ),
  ClinicalCard(
    title: 'Ambulance',
    caption: 'Call 96741 08108',
    icon: Icons.emergency_rounded,
    color: Color(0xFFD92D20),
    tap: HomeTap.call,
  ),
];

/// The hospital's ambulance and emergency line, given by the hospital.
const emergencyPhoneUri = 'tel:+919674108108';

const hospitalMapsUri = 'https://maps.app.goo.gl/UGKJ3hgTcLZqGY4V9';
