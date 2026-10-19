import 'package:flutter/material.dart';

// Emergency number, campus address, specialist names, the 40% offer,
// and the "100,000+ families" line are unconfirmed Stitch copy.
// Replace them with hospital-approved values before release.

class MedicalService {
  const MedicalService({
    required this.title,
    required this.subtitle,
    required this.telugu,
    required this.action,
    required this.icon,
    required this.urgent,
  });

  final String title;
  final String subtitle;
  final String telugu;
  final String action;
  final IconData icon;
  final bool urgent;
}

class Specialist {
  const Specialist({
    required this.name,
    required this.qualification,
    required this.experience,
    required this.availability,
  });

  final String name;
  final String qualification;
  final String experience;
  final String availability;
}

const medicalServices = <MedicalService>[
  MedicalService(
    title: 'Consultation',
    subtitle: 'Consult our specialists',
    telugu: 'స్పెషలిస్ట్ డాక్టర్లు',
    action: 'Book Slot',
    icon: Icons.medical_services_outlined,
    urgent: false,
  ),
  MedicalService(
    title: '4D Echo',
    subtitle: 'Advanced heart imaging',
    telugu: 'గుండె స్కానింగ్ పరీక్ష',
    action: 'View Details',
    icon: Icons.monitor_heart_outlined,
    urgent: false,
  ),
  MedicalService(
    title: 'CT Calcium Score',
    subtitle: 'Assess heart health',
    telugu: 'కాల్షియం స్కోర్ టెస్ట్',
    action: 'Schedule',
    icon: Icons.medical_information_outlined,
    urgent: false,
  ),
  MedicalService(
    title: 'CT Coronary Angiogram',
    subtitle: 'Advanced coronary imaging',
    telugu: 'యాంజియోగ్రామ్ వివరాలు',
    action: 'Learn More',
    icon: Icons.monitor_heart,
    urgent: false,
  ),
  MedicalService(
    title: 'Emergency',
    subtitle: '24x7 Immediate assistance • ICU & Trauma Care',
    telugu: 'అత్యవసర చికిత్స విభాగం',
    action: 'Call 24/7',
    icon: Icons.emergency_outlined,
    urgent: true,
  ),
  MedicalService(
    title: 'Lab Services',
    subtitle: 'Diagnostic tests & blood work',
    telugu: 'ల్యాబ్ & రక్త పరీక్షలు',
    action: 'Book Home Test',
    icon: Icons.science_outlined,
    urgent: false,
  ),
  MedicalService(
    title: 'Ambulance',
    subtitle: 'Ambulance assistance',
    telugu: 'అంబులెన్స్ సదుపాయం',
    action: 'Dispatch / Call',
    icon: Icons.airport_shuttle_outlined,
    urgent: false,
  ),
];

const specialists = <Specialist>[
  Specialist(
    name: 'Dr. K. Srinivas Rao',
    qualification: 'MD, DM (Cardiology)',
    experience: '18+ Yrs',
    availability: 'Available',
  ),
  Specialist(
    name: 'Dr. P. Madhavi Latha',
    qualification: 'MD, DM (Neurology)',
    experience: '14+ Yrs',
    availability: 'Tomorrow',
  ),
  Specialist(
    name: 'Dr. V. Ramana Murthy',
    qualification: 'MD (General Medicine)',
    experience: '22+ Yrs',
    availability: 'Available',
  ),
];

const emergencyPhoneUri = 'tel:108';

const hospitalDirectionsQuery =
    'Mallika Multi-Speciality Campus, Opp. Collectorate Road, Near Metro Junction';
