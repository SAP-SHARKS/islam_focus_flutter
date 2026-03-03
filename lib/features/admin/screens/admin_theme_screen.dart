// lib/features/admin/screens/admin_theme_screen.dart
//
// This screen is for the ADMIN to change app themes.
// Access it by navigating to AdminThemeScreen().
// Only users with is_admin=true in profiles table can save changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:islam_focus_flutter/core/config/supabase_config.dart';
import 'package:islam_focus_flutter/core/theme/app_theme.dart';
import 'package:islam_focus_flutter/core/theme/theme_provider.dart';

class AdminThemeScreen extends ConsumerStatefulWidget {
  const AdminThemeScreen({super.key});

  @override
  ConsumerState<AdminThemeScreen> createState() => _AdminThemeScreenState();
}

class _AdminThemeScreenState extends ConsumerState<AdminThemeScreen> {
  bool _isSaving = false;
  late Map<String, TextEditingController> _controllers;
  String _brightness = 'light';

  final _colorFields = [
    ('primary_color', 'Primary Color', '#5B9BD5'),
    ('secondary_color', 'Secondary Color', '#2E7D6F'),
    ('accent_color', 'Accent Color', '#F0C27B'),
    ('background_color', 'Background', '#F7F9FC'),
    ('surface_color', 'Surface', '#FFFFFF'),
    ('card_color', 'Card', '#FFFFFF'),
    ('text_primary', 'Text Primary', '#2C3E50'),
    ('text_secondary', 'Text Secondary', '#7F8C8D'),
    ('success_color', 'Success', '#27AE60'),
    ('error_color', 'Error', '#E74C3C'),
    ('breathing_start_color', 'Breathing Start', '#E8F4FD'),
    ('breathing_end_color', 'Breathing End', '#5B9BD5'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final field in _colorFields) {
      _controllers[field.$1] = TextEditingController(text: field.$3);
    }
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    try {
      final response = await Supabase.instance.client
          .from(SupabaseConfig.appThemesTable)
          .select()
          .eq('is_active', true)
          .single();

      setState(() {
        for (final field in _colorFields) {
          _controllers[field.$1]?.text = response[field.$1] ?? field.$3;
        }
        _brightness = response['brightness'] ?? 'light';
      });
    } catch (e) {
      // Use defaults
    }
  }

  Future<void> _saveTheme() async {
    setState(() => _isSaving = true);

    try {
      final themeData = <String, dynamic>{
        'brightness': _brightness,
        'updated_at': DateTime.now().toIso8601String(),
      };
      for (final field in _colorFields) {
        themeData[field.$1] = _controllers[field.$1]?.text ?? field.$3;
      }

      // Deactivate all themes, then activate this one
      await Supabase.instance.client
          .from(SupabaseConfig.appThemesTable)
          .update({'is_active': false})
          .neq('id', '');

      await Supabase.instance.client
          .from(SupabaseConfig.appThemesTable)
          .upsert({
        ...themeData,
        'name': 'Admin Theme',
        'is_active': true,
      });

      // Update local theme
      ref.read(themeProvider.notifier).updateTheme(
            AppThemeData.fromJson(themeData),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Theme saved successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Preview the theme locally without saving
  void _previewTheme() {
    final themeData = <String, dynamic>{
      'brightness': _brightness,
    };
    for (final field in _colorFields) {
      themeData[field.$1] = _controllers[field.$1]?.text ?? field.$3;
    }
    ref.read(themeProvider.notifier).updateTheme(
          AppThemeData.fromJson(themeData),
        );
  }

  Color _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Theme Editor'),
        actions: [
          TextButton(
            onPressed: _previewTheme,
            child: Text('Preview', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Brightness toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Theme Mode',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'light', label: Text('Light')),
                      ButtonSegment(value: 'dark', label: Text('Dark')),
                    ],
                    selected: {_brightness},
                    onSelectionChanged: (v) => setState(() => _brightness = v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Color fields
          Text(
            'Colors',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...List.generate(_colorFields.length, (i) {
            final field = _colorFields[i];
            final controller = _controllers[field.$1]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Color preview
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(controller.text),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: field.$2,
                        hintText: field.$3,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTheme,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save & Publish Theme'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
