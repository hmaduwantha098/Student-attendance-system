import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_store.dart';
import 'university_catalog.dart';

class UniversitiesScreen extends StatefulWidget {
  const UniversitiesScreen({super.key});

  @override
  State<UniversitiesScreen> createState() => _UniversitiesScreenState();
}

class _UniversitiesScreenState extends State<UniversitiesScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  final AttendanceStore _store = AttendanceStore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(SriLankanInstitution institution) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (institution.name.toLowerCase().contains(query)) return true;
    if (institution.city.toLowerCase().contains(query)) return true;
    for (final faculty in institution.courses.entries) {
      if (faculty.key.toLowerCase().contains(query)) return true;
      if (faculty.value.any((course) => course.toLowerCase().contains(query))) {
        return true;
      }
    }
    return false;
  }

  List<SriLankanInstitution> get _stateUniversities =>
      sriLankanStateUniversities.where(_matches).toList();

  List<SriLankanInstitution> get _universityColleges =>
      sriLankanUniversityColleges.where(_matches).toList();

  List<SriLankanInstitution> get _technologicalInstitutes =>
      sriLankanTechnologicalInstitutes.where(_matches).toList();

  @override
  Widget build(BuildContext context) {
    final stateUniversities = _stateUniversities;
    final universityColleges = _universityColleges;
    final technologicalInstitutes = _technologicalInstitutes;
    final customUniversities = _store.customUniversities;
    final visibleCount =
        stateUniversities.length +
        universityColleges.length +
        technologicalInstitutes.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'University Directory',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          TextField(
            key: const Key('universities-search'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search universities, faculties or courses',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _query.trim().isEmpty
                ? '$sriLankanStateUniversityCount state universities · '
                      '$sriLankanTechnologicalInstituteCount advanced '
                      'technological institutes · '
                      '$sriLankanUniversityCollegeCount university colleges'
                : '$visibleCount of ${sriLankanInstitutions.length} institutions match "${_query.trim()}"',
            key: const Key('universities-count'),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (visibleCount == 0 && customUniversities.isEmpty)
            _buildEmptyState()
          else ...[
            if (stateUniversities.isNotEmpty) ...[
              _buildSectionTitle(
                'State universities (${stateUniversities.length})',
                Icons.account_balance_rounded,
              ),
              for (final institution in stateUniversities)
                _buildInstitutionCard(institution),
            ],
            if (universityColleges.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSectionTitle(
                'University colleges (${universityColleges.length})',
                Icons.apartment_rounded,
              ),
              for (final institution in universityColleges)
                _buildInstitutionCard(institution),
            ],
            if (technologicalInstitutes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSectionTitle(
                'Advanced technological institutes '
                '(${technologicalInstitutes.length})',
                Icons.precision_manufacturing_rounded,
              ),
              for (final institution in technologicalInstitutes)
                _buildInstitutionCard(institution),
            ],
            if (customUniversities.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSectionTitle(
                'Added by you (${customUniversities.length})',
                Icons.person_add_alt_1_rounded,
              ),
              for (final university in customUniversities)
                _buildCustomCard(university),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionCard(SriLankanInstitution institution) {
    final kind = universityKindFor(institution.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ExpansionTile(
          key: ValueKey('university-${institution.name}'),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              institution.name.substring(0, 1),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: primaryBlue,
              ),
            ),
          ),
          title: Text(
            institution.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${kind?.label ?? 'Institution'} · ${institution.city} · '
            '${institution.faculties.length} faculties · '
            '${institution.courseCount} courses',
            style: GoogleFonts.inter(fontSize: 12, color: textGrey),
          ),
          children: [
            for (final faculty in institution.faculties) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    faculty,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: textDark,
                    ),
                  ),
                ),
              ),
              for (final course in institution.courses[faculty]!)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 6, color: textGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textGrey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard(String university) {
    final faculties = _store.facultiesFor(university);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              university,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              faculties.isEmpty
                  ? 'No faculties added yet.'
                  : '${faculties.length} faculties you added · '
                        '${faculties.join(', ')}',
              style: GoogleFonts.inter(fontSize: 12, color: textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 46, color: textGrey),
          const SizedBox(height: 12),
          Text(
            'No institutions match "${_query.trim()}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a university, city, faculty or course name.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: textGrey),
          ),
        ],
      ),
    );
  }
}
