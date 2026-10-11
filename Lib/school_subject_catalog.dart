const String allSubjectsOption = 'All subjects';

const primarySchoolSubjects = [
  'Sinhala Language',
  'Tamil Language',
  'English Language',
  'Mathematics',
  'Environmental Studies',
  'Religion',
  'Aesthetic Activities',
  'Health and Physical Education',
];

const juniorSecondarySubjects = [
  'Sinhala Language',
  'Tamil Language',
  'English Language',
  'Mathematics',
  'Science',
  'History',
  'Religion',
  'Second National Language',
  'Geography',
  'Civic Education',
  'Health and Physical Education',
  'Aesthetic Education',
  'Practical and Technical Skills',
  'Information and Communication Technology',
];

const ordinaryLevelSubjects = [
  'Sinhala Language and Literature',
  'Tamil Language and Literature',
  'English Language',
  'Mathematics',
  'Science',
  'History',
  'Religion',
  'Business and Accounting Studies',
  'Geography',
  'Civic Education',
  'Entrepreneurship Studies',
  'Second National Language',
  'Art',
  'Music',
  'Dancing',
  'Drama and Theatre',
  'Health and Physical Education',
  'Information and Communication Technology',
  'Agriculture and Food Technology',
  'Aquatic Bioresources Technology',
  'Design and Construction Technology',
  'Design and Mechanical Technology',
  'Electronic and Electrical Technology',
];

const advancedLevelStreams = [
  'Arts',
  'Commerce',
  'Biological Science',
  'Physical Science',
  'Technology',
];

const advancedLevelCommonSubjects = [
  'General English',
  'General Information Technology',
];

const advancedLevelSubjectsByStream = {
  'Arts': [
    'Buddhist Civilization',
    'Hindu Civilization',
    'Islam',
    'Christian Civilization',
    'Sinhala',
    'Tamil',
    'English',
    'History',
    'Geography',
    'Political Science',
    'Economics',
    'Logic and Scientific Method',
    'Communication and Media Studies',
    'Home Economics',
    'Art',
    'Music',
    'Dancing',
    'Drama and Theatre',
    'Japanese',
    'French',
    'German',
    'Information and Communication Technology',
  ],
  'Commerce': [
    'Accounting',
    'Business Studies',
    'Economics',
    'Business Statistics',
    'Information and Communication Technology',
  ],
  'Biological Science': [
    'Biology',
    'Chemistry',
    'Physics',
    'Agricultural Science',
  ],
  'Physical Science': [
    'Combined Mathematics',
    'Physics',
    'Chemistry',
    'Information and Communication Technology',
  ],
  'Technology': [
    'Engineering Technology',
    'Biosystems Technology',
    'Science for Technology',
    'Information and Communication Technology',
  ],
};

List<String> subjectsForSchoolGrade(String grade, {String stream = ''}) {
  final gradeNumber = int.tryParse(
    RegExp(r'\d+').firstMatch(grade)?.group(0) ?? '',
  );
  if (gradeNumber == null) return const [];
  if (gradeNumber <= 5) return primarySchoolSubjects;
  if (gradeNumber <= 9) return juniorSecondarySubjects;
  if (gradeNumber <= 11) return ordinaryLevelSubjects;

  final streamSubjects = advancedLevelSubjectsByStream[stream];
  if (streamSubjects != null) {
    return [...advancedLevelCommonSubjects, ...streamSubjects];
  }
  return {
    ...advancedLevelCommonSubjects,
    for (final subjects in advancedLevelSubjectsByStream.values) ...subjects,
  }.toList()..sort();
}
