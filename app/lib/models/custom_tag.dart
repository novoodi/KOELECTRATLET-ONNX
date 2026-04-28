import 'package:flutter/material.dart';

class CustomTag {
  final String id;
  final String label;
  final IconData icon; // ReactNode 대신 IconData를 사용합니다.

  const CustomTag({
    required this.id,
    required this.label,
    required this.icon,
  });
}