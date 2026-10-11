import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_store.dart';
import 'setup_editor.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
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

  bool _matches(String name, String scope) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return name.toLowerCase().contains(query) ||
        scope.toLowerCase().contains(query);
  }

  List<_CategoryGroup> _buildGroups() {
    final groups = <_CategoryGroup>[
      _CategoryGroup(
        title: 'School grades',
        icon: Icons.school_rounded,
        items: [
          for (final grade in _store.customSchoolGrades)
            _CategoryItem(
              name: grade,
              scope: 'School grade',
              rename: (value) => _store.renameSchoolGrade(grade, value),
            ),
        ],
      ),
      _CategoryGroup(
        title: 'University years',
        icon: Icons.calendar_month_rounded,
        items: [
          for (final year in _store.customUniversityYears)
            _CategoryItem(
              name: year,
              scope: 'University year',
              rename: (value) => _store.renameUniversityYear(year, value),
            ),
        ],
      ),
      _CategoryGroup(
        title: 'Institutions',
        icon: Icons.account_balance_rounded,
        items: [
          for (final university in _store.customUniversities)
            _CategoryItem(
              name: university,
              scope: 'University / institute',
              rename: (value) => _store.renameUniversity(university, value),
            ),
        ],
      ),
      _CategoryGroup(
        title: 'Faculties',
        icon: Icons.apartment_rounded,
        items: [
          for (final entry in _store.customFacultyEntries)
            _CategoryItem(
              name: entry.faculty,
              scope: entry.scope,
              rename: (value) => _store.renameFaculty(
                universityName: entry.universityName,
                currentName: entry.faculty,
                newName: value,
              ),
            ),
        ],
      ),
      _CategoryGroup(
        title: 'School subjects',
        icon: Icons.menu_book_rounded,
        items: [
          for (final entry in _store.customSchoolSubjectEntries)
            _CategoryItem(
              name: entry.subject,
              scope: entry.scope,
              rename: (value) => _store.renameSchoolSubject(
                grade: entry.grade,
                stream: entry.stream,
                currentName: entry.subject,
                newName: value,
              ),
            ),
        ],
      ),
      _CategoryGroup(
        title: 'Courses',
        icon: Icons.co_present_rounded,
        items: [
          for (final entry in _store.customCampusCourseEntries)
            _CategoryItem(
              name: entry.course,
              scope: entry.scope,
              rename: (value) => _store.renameCampusSubject(
                universityName: entry.universityName,
                facultyName: entry.facultyName,
                year: entry.year,
                currentName: entry.course,
                newName: value,
              ),
            ),
        ],
      ),
    ];

    return [
      for (final group in groups)
        if (group.items.any((item) => _matches(item.name, item.scope)))
          group.copyWith(
            items: [
              for (final item in group.items)
                if (_matches(item.name, item.scope)) item,
            ],
          ),
    ];
  }

  int get _totalCount =>
      _store.customSchoolGrades.length +
      _store.customUniversityYears.length +
      _store.customUniversities.length +
      _store.customFacultyEntries.length +
      _store.customSchoolSubjectEntries.length +
      _store.customCampusCourseEntries.length;

  Future<void> _rename(_CategoryItem item) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameEntryDialog(
        title: 'Edit category',
        label: 'Name',
        initialValue: item.name,
      ),
    );
    if (!mounted || newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      _showMessage('Enter a name.');
      return;
    }
    if (trimmed == item.name) return;
    if (!item.rename(trimmed)) {
      _showMessage('"$trimmed" already exists in this list.');
      return;
    }
    _showMessage('Updated to "$trimmed".');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Saved Categories',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final groups = _buildGroups();
          final visibleCount = groups.fold<int>(
            0,
            (total, group) => total + group.items.length,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  key: const Key('categories-search'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search grades, subjects, institutions, courses',
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _query.trim().isEmpty
                        ? '$_totalCount categories added'
                        : '$visibleCount of $_totalCount categories match "${_query.trim()}"',
                    key: const Key('categories-count'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: groups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      group.icon,
                                      size: 18,
                                      color: primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${group.title} (${group.items.length})',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      for (
                                        var position = 0;
                                        position < group.items.length;
                                        position++
                                      )
                                        _buildRow(
                                          group.items[position],
                                          position == group.items.length - 1,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(_CategoryItem item, bool isLast) {
    return Column(
      children: [
        ListTile(
          key: ValueKey('category-${item.name}'),
          onTap: () => _rename(item),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          title: Text(
            item.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          subtitle: Text(
            item.scope,
            style: GoogleFonts.inter(fontSize: 12, color: textGrey),
          ),
          trailing: IconButton(
            tooltip: 'Edit ${item.name}',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(item),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 14, endIndent: 14),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.category_outlined,
              size: 46,
              color: textGrey,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'No categories match "${_query.trim()}"'
                  : 'No categories added yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try a different search term.'
                  : 'Add grades, subjects, years, institutions or courses from '
                        'the Mark Attendance, Students or Reports screens.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textGrey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGroup {
  const _CategoryGroup({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_CategoryItem> items;

  _CategoryGroup copyWith({required List<_CategoryItem> items}) =>
      _CategoryGroup(title: title, icon: icon, items: items);
}

class _CategoryItem {
  const _CategoryItem({
    required this.name,
    required this.scope,
    required this.rename,
  });

  final String name;
  final String scope;
  final bool Function(String newName) rename;
}
