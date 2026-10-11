/// Reference data for Sri Lankan higher education institutions.
///
/// `sriLankanStateUniversities` holds the 19 state universities: the 17
/// universities under the University Grants Commission plus the Buddhist and
/// Pali University and Bhiksu University under the Ministry of Higher
/// Education. `sriLankanUniversityColleges` holds the degree awarding
/// university colleges / recognised institutes, plus the University of
/// Vocational Technology (UoVT) university colleges that award NVQ Level 5
/// and 6 Higher National Diplomas. `sriLankanTechnologicalInstitutes` holds
/// the 19 Advanced Technological Institutes (ATIs) of the Sri Lanka
/// Institute of Advanced Technological Education (SLIATE) and the Higher
/// National Diploma programmes each one offers.
///
/// Each institution lists its faculties and the courses offered under them.
/// These built-in lists are read-only inside the app: administrators can add
/// more faculties and courses from the Mark Attendance, Students and Reports
/// screens, and the "University Directory" screen lists everything together.
library;

enum UniversityKind {
  stateUniversity,
  universityCollege,
  advancedTechnologicalInstitute,
}

extension UniversityKindLabel on UniversityKind {
  String get label => switch (this) {
    UniversityKind.stateUniversity => 'State university',
    UniversityKind.universityCollege => 'University college',
    UniversityKind.advancedTechnologicalInstitute =>
      'Advanced technological institute',
  };
}

class SriLankanInstitution {
  const SriLankanInstitution({
    required this.name,
    required this.city,
    required this.courses,
  });

  final String name;
  final String city;
  final Map<String, List<String>> courses;

  List<String> get faculties => courses.keys.toList()..sort();

  int get courseCount =>
      courses.values.fold(0, (total, list) => total + list.length);
}

const List<SriLankanInstitution> sriLankanStateUniversities = [
  SriLankanInstitution(
    name: 'University of Colombo',
    city: 'Colombo',
    courses: {
      'Faculty of Arts': [
        'BA (Hons) in Sinhala',
        'BA (Hons) in English',
        'BA (Hons) in Tamil',
        'BA (Hons) in Arabic',
        'BA in Geography',
        'BA in Economics',
      ],
      'Faculty of Education': [
        'BA in Education (Hons)',
        'BEd (Hons) in Education',
        'BA in Sports Science',
      ],
      'Faculty of Engineering': [
        'BSc in Civil Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering',
      ],
      'Faculty of Indigenous Medicine': [
        'BSc in Indigenous Medicine (Ayurveda)',
      ],
      'Faculty of Law': ['LLB (Hons)'],
      'Faculty of Management and Finance': [
        'BBA (Hons) in Accounting',
        'BSc in Business Administration',
        'BSc in Business Management',
        'BSc in Banking and Finance',
        'BSc in Financial Economics',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Nursing': [
        'BSc in Nursing',
        'Higher Diploma in Nursing',
        'BSc in Midwifery',
      ],
      'Faculty of Science': [
        'BSc in Physics',
        'BSc in Chemistry',
        'BSc in Mathematics',
        'BSc in Statistics',
        'BSc in Botany',
        'BSc in Zoology',
      ],
      'Faculty of Technology': [
        'BSc in Engineering Technology (Civil)',
        'BSc in Engineering Technology (Mechanical)',
        'BSc in Engineering Technology (Electrical)',
        'BTech in Information Technology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of Peradeniya',
    city: 'Peradeniya',
    courses: {
      'Faculty of Agriculture': [
        'BSc in Agriculture',
        'BSc in Agricultural Technology and Management',
        'BSc in Food Science and Technology',
        'BSc in Plantation Management',
        'BSc in Agricultural Economics',
      ],
      'Faculty of Allied Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
        'BSc in Physiotherapy',
        'BSc in Pharmacy',
      ],
      'Faculty of Arts': [
        'BA in Sinhala',
        'BA in English',
        'BA in Tamil',
        'BA in Sanskrit',
        'BA in Buddhist Studies',
        'BA in Arabic',
      ],
      'Faculty of Dental Sciences': ['BDS'],
      'Faculty of Engineering': [
        'BSc in Civil Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering',
        'BSc in Computer Engineering',
        'BSc in Chemical and Process Engineering',
      ],
      'Faculty of Management': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Tourism and Hospitality Management',
        'BSc in Management and Economics',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Science': [
        'BSc in Physics',
        'BSc in Chemistry',
        'BSc in Mathematics',
        'BSc in Statistics',
        'BSc in Molecular Biology',
        'BSc in Geology',
      ],
      'Faculty of Veterinary Medicine and Animal Science': [
        'BSc in Veterinary Medicine and Animal Science',
        'BSc in Animal Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of Sri Jayewardenepura',
    city: 'Nugegoda',
    courses: {
      'Faculty of Allied Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
        'BSc in Pharmacy',
        'BSc in Physiotherapy',
      ],
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
        'BSc in Food Science and Technology',
      ],
      'Faculty of Computing': [
        'BSc in Information Technology',
        'BSc in Information Systems',
        'BSc in Data Science and Analytics',
        'BSc in Cyber Security',
      ],
      'Faculty of Dental Sciences': ['BDS'],
      'Faculty of Engineering': [
        'BSc in Civil Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering',
      ],
      'Faculty of Humanities and Social Sciences': [
        'BA in Sinhala',
        'BA in English',
        'BA in Pali',
        'BA in Buddhist Studies',
        'BA in Sociology',
        'BA in Archaeology',
      ],
      'Faculty of Management Studies and Commerce': [
        'BBA in Accounting',
        'BSc in Business Administration',
        'BSc in Business Management',
        'BSc in Tourism and Hospitality Management',
        'BSc in Management and Public Policy',
      ],
      'Faculty of Medical Sciences': ['MBBS'],
      'Faculty of Technology': [
        'BSc in Biotechnology',
        'BSc in Food Science and Technology',
      ],
      'Faculty of Urban and Aquatic Bioresources': [
        'BSc in Fisheries and Aquaculture',
        'BSc in Tropical Aquaculture',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of Kelaniya',
    city: 'Kelaniya',
    courses: {
      'Faculty of Arts': [
        'BA in Sinhala',
        'BA in English',
        'BA in Tamil',
        'BA in Arabic',
        'BA in Sanskrit',
        'BA in Buddhist Studies',
      ],
      'Faculty of Commerce and Management Studies': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Human Resource Management',
        'BSc in Management',
      ],
      'Faculty of Computing and Technology': [
        'BSc in Information Technology',
        'BSc in Software Engineering',
        'BSc in Data Science',
      ],
      'Faculty of Law': ['LLB (Hons)'],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Psychology': ['BA in Psychology'],
      'Faculty of Science': [
        'BSc in Physics',
        'BSc in Chemistry',
        'BSc in Mathematics',
        'BSc in Statistics',
        'BSc in Biological Science',
        'BSc in Botany',
      ],
      'Faculty of Social Sciences': [
        'BA in Sociology',
        'BA in Archaeology',
        'BA in Geography',
        'BA in International Relations',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of Moratuwa',
    city: 'Moratuwa',
    courses: {
      'Faculty of Architecture': ['BArch (Hons) in Architecture'],
      'Faculty of Business': [
        'BSc in Business Administration',
        'BSc in Entrepreneurship and Small Business Management',
      ],
      'Faculty of Engineering': [
        'BSc in Civil Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering',
        'BSc in Computer Science and Engineering',
        'BSc in Textile Engineering',
        'BSc in Materials Engineering',
        'BSc in Chemical and Process Engineering',
      ],
      'Faculty of Information Technology': [
        'BSc in Information Technology',
        'BSc in Data Engineering and Analytics',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Science': [
        'BSc in Physics',
        'BSc in Chemistry',
        'BSc in Mathematics',
        'BSc in Applied Chemistry',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of Jaffna',
    city: 'Jaffna',
    courses: {
      'Faculty of Agriculture': [
        'BSc in Agriculture',
        'BSc in Agricultural Technology and Management',
        'BSc in Food Science and Technology',
        'BSc in Animal Science',
      ],
      'Faculty of Allied Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
        'BSc in Pharmacy',
      ],
      'Faculty of Arts': [
        'BA in Tamil',
        'BA in Sinhala',
        'BA in English',
        'BA in Arabic',
      ],
      'Faculty of Engineering': [
        'BSc in Civil Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering',
        'BSc in Computer Engineering',
      ],
      'Faculty of Hindu Studies': [
        'BA in Hindu Studies',
        'BA in Sanskrit',
        'BA in Indian Philosophy',
      ],
      'Faculty of Management Studies and Commerce': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Management',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Science': [
        'BSc in Physics',
        'BSc in Chemistry',
        'BSc in Mathematics',
        'BSc in Biological Science',
        'BSc in Physical Science',
      ],
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Engineering Technology (Civil)',
      ],
      'Sir Ponnambalam Ramanathan Faculty of Performing and Visual Arts': [
        'BA in Music',
        'BA in Dance',
        'BA in Drama',
        'BA in Fine Arts',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of Ruhuna',
    city: 'Matara',
    courses: {
      'Faculty of Agriculture': [
        'BSc in Agriculture',
        'BSc in Agricultural Technology and Management',
        'BSc in Food Science and Technology',
      ],
      'Faculty of Allied Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
        'BSc in Pharmacy',
      ],
      'Faculty of Engineering': [
        'BSc in Computer Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Civil Engineering',
        'BSc in Mechanical Engineering',
      ],
      'Faculty of Fisheries and Marine Sciences and Technology': [
        'BSc in Fisheries Science',
        'BSc in Marine Science',
      ],
      'Faculty of Humanities and Social Sciences': [
        'BA in Sinhala',
        'BA in English',
        'BA in Tamil',
        'BA in Archaeology',
      ],
      'Faculty of Management and Finance': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Financial Management',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Science': [
        'BSc in Physics',
        'BSc in Chemistry',
        'BSc in Mathematics',
        'BSc in Biological Science',
      ],
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Engineering Technology (Electrical)',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Eastern University, Sri Lanka',
    city: 'Vantharumoolai',
    courses: {
      'Faculty of Agriculture': [
        'BSc in Agriculture',
        'BSc in Agricultural Technology and Management',
        'BSc in Livestock Production',
      ],
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
        'BSc in Biosystems Technology',
      ],
      'Faculty of Arts and Culture': [
        'BA in Tamil',
        'BA in Sinhala',
        'BA in English',
      ],
      'Faculty of Commerce and Management': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Management',
      ],
      'Faculty of Health Care Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
        'BSc in Physiotherapy',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Science': [
        'BSc in Physics',
        'BSc in Chemistry',
        'BSc in Mathematics',
        'BSc in Biological Science',
        'BSc in Physical Science',
      ],
      'Faculty of Siddha Medicine': ['Bachelor of Siddha Medicine'],
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Engineering Technology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'South Eastern University of Sri Lanka',
    city: 'Oluvil',
    courses: {
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
        'BSc in Biosystems Technology',
      ],
      'Faculty of Arts and Culture': [
        'BA in Sinhala',
        'BA in Tamil',
        'BA in English',
      ],
      'Faculty of Engineering': [
        'BSc in Computer Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Civil Engineering',
        'BSc in Mechanical Engineering',
      ],
      'Faculty of Islamic Studies and Arabic Language': [
        'BA in Islamic Studies',
        'BA in Arabic Language',
      ],
      'Faculty of Management and Commerce': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Management',
      ],
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Engineering Technology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Rajarata University of Sri Lanka',
    city: 'Mihintale',
    courses: {
      'Faculty of Agriculture': [
        'BSc in Agriculture',
        'BSc in Agricultural Technology and Management',
        'BSc in Food Science and Technology',
        'BSc in Natural Resources Management',
      ],
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
      ],
      'Faculty of Medicine and Allied Sciences': [
        'MBBS',
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
        'BSc in Pharmacy',
      ],
      'Faculty of Management Studies': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Management',
      ],
      'Faculty of Social Sciences and Humanities': [
        'BA in Sinhala',
        'BA in English',
        'BA in Tamil',
        'BA in Archaeology',
      ],
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Biotechnology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Sabaragamuwa University of Sri Lanka',
    city: 'Belihuloya',
    courses: {
      'Faculty of Agricultural Sciences': [
        'BSc in Agriculture',
        'BSc in Agricultural Technology and Management',
        'BSc in Food Science and Technology',
      ],
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
        'BSc in Biosystems Technology',
      ],
      'Faculty of Computing': [
        'BSc in Information Technology',
        'BSc in Information Systems',
        'BSc in Data Analytics',
      ],
      'Faculty of Geomatics': [
        'BSc in Surveying and Geomatics',
        'BSc in Surveying Science',
        'BSc in Geoinformatics',
      ],
      'Faculty of Management Studies': [
        'BSc in Business Administration',
        'BSc in Management',
        'BSc in Accounting and Finance',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Social Sciences and Languages': [
        'BA in Sinhala',
        'BA in Tamil',
        'BA in English',
      ],
      'Faculty of Technology': [
        'BSc in Engineering Technology (Civil)',
        'BSc in Engineering Technology (Mechanical)',
        'BSc in Biotechnology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Wayamba University of Sri Lanka',
    city: 'Kuliyapitiya',
    courses: {
      'Faculty of Agriculture and Plantation Management': [
        'BSc in Agriculture',
        'BSc in Plantation Management',
        'BSc in Agribusiness Management',
      ],
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
      ],
      'Faculty of Business Studies and Finance': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Financial Management',
        'BSc in Banking and Finance',
      ],
      'Faculty of Livestock, Fisheries and Nutrition': [
        'BSc in Animal Science',
        'BSc in Fisheries Science',
        'BSc in Food Science and Technology',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Engineering Technology',
        'BSc in Biosystems Technology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Uva Wellassa University of Sri Lanka',
    city: 'Badulla',
    courses: {
      'Faculty of Animal Science and Export Agriculture': [
        'BSc in Export Agriculture',
        'BSc in Animal Science',
        'BSc in Aquaculture',
      ],
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
      ],
      'Faculty of Management': [
        'BSc in Business Administration',
        'BSc in Management',
        'BSc in Accounting and Finance',
      ],
      'Faculty of Medicine': ['MBBS'],
      'Faculty of Technological Studies': [
        'BSc in Information Technology',
        'BSc in Engineering Technology',
        'BSc in Biotechnology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'The Open University of Sri Lanka',
    city: 'Nawala',
    courses: {
      'Faculty of Education': [
        'BA in Education (Hons)',
        'BEd (Hons) in Education',
      ],
      'Faculty of Engineering Technology': [
        'BSc in Engineering Technology (Civil)',
        'BSc in Engineering Technology (Mechanical)',
        'BSc in Engineering Technology (Electrical)',
        'BTech in Information Technology',
      ],
      'Faculty of Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
      ],
      'Faculty of Humanities and Social Sciences': [
        'BA in Sinhala',
        'BA in English',
        'BA in Tamil',
      ],
      'Faculty of Management Studies': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
      ],
      'Faculty of Natural Sciences': [
        'BSc in Biology',
        'BSc in Chemistry',
        'BSc in Physics',
        'BSc in Mathematics',
        'BSc in Computer Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of the Visual & Performing Arts',
    city: 'Colombo',
    courses: {
      'Faculty of Dance and Drama': [
        'BFA in Dance',
        'BFA in Drama',
        'BA in Drama',
      ],
      'Faculty of Design': [
        'BFA in Fashion Design',
        'BFA in Media and Communication Design',
      ],
      'Faculty of Music': ['BFA in Music', 'BA in Music'],
      'Faculty of Visual Arts': [
        'BFA in Painting',
        'BFA in Sculpture',
        'BFA in Graphic Design',
        'BFA in Applied Arts',
        'BFA in Photography',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Gampaha Wickramarachchi University of Indigenous Medicine',
    city: 'Yakkala',
    courses: {
      'Faculty of Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
      ],
      'Faculty of Indigenous Medicine': [
        'Bachelor of Ayurveda',
        'Bachelor of Unani Medicine',
      ],
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Biotechnology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University of Vavuniya',
    city: 'Vavuniya',
    courses: {
      'Faculty of Applied Sciences': [
        'BSc in Applied Sciences (Biological Science)',
        'BSc in Applied Sciences (Physical Science)',
      ],
      'Faculty of Business Studies': [
        'BSc in Banking and Insurance',
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
      ],
      'Faculty of Technological Studies': [
        'BSc in Information Technology',
        'BSc in Engineering Technology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Buddhist and Pali University of Sri Lanka',
    city: 'Homagama',
    courses: {
      'Faculty of Buddhist and Pali Studies': [
        'BA in Buddhist Studies',
        'BA in Pali Studies',
        'BA in Sanskrit',
        'BA in Philosophy',
        'BA in Comparative Religion',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Bhiksu University of Sri Lanka',
    city: 'Anuradhapura',
    courses: {
      'Faculty of Pali and Buddhist Studies': [
        'BA in Pali Studies',
        'BA in Buddhist Studies',
        'BA in Sanskrit',
        'BA in Comparative Study of Religions',
      ],
    },
  ),
];

/// The 19 Advanced Technological Institutes (ATIs) of the Sri Lanka
/// Institute of Advanced Technological Education (SLIATE). Each ATI offers
/// Higher National Diploma (HND) programmes; mechanical, electrical and
/// civil engineering streams are each listed separately as HNDE programmes.
const List<SriLankanInstitution> sriLankanTechnologicalInstitutes = [
  SriLankanInstitution(
    name: 'ATI Colombo (Mattakkuliya / Maradana)',
    city: 'Colombo',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Higher National Diploma in Accountancy)',
        'HNDIT (Higher National Diploma in Information Technology)',
        'HNDM (Higher National Diploma in Management)',
        'HNDE (Civil Engineering)',
        'HNDE (Electrical & Electronic Engineering)',
        'HNDE (Mechanical Engineering)',
        'HND Building Services Engineering',
        'HNDQS (Quantity Surveying)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Dehiwala',
    city: 'Dehiwala',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HNDBA (Business Administration)',
        'HNDBF (Business Finance)',
        'HNDTHM (Tourism and Hospitality Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Kandy',
    city: 'Kandy',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HNDTHM (Tourism and Hospitality Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Labuduwa (Galle)',
    city: 'Galle',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HNDE (Civil Engineering)',
        'HNDE (Electrical & Electronic Engineering)',
        'HNDE (Mechanical Engineering)',
        'HNDT - Agriculture',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Kurunegala',
    city: 'Kurunegala',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Badulla',
    city: 'Badulla',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HNDTHM (Tourism and Hospitality Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Jaffna',
    city: 'Jaffna',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HNDE (Civil Engineering)',
        'HNDE (Electrical & Electronic Engineering)',
        'HND Building Services Engineering',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Hardy ATI - Ampara',
    city: 'Ampara',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HNDT - Agriculture',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Batticaloa',
    city: 'Batticaloa',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Naiwala (Gampaha)',
    city: 'Gampaha',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HNDFT (Food Technology)',
        'HNDT - Agriculture',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Kegalle',
    city: 'Kegalle',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Anuradhapura',
    city: 'Anuradhapura',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Ratnapura',
    city: 'Ratnapura',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Matara',
    city: 'Matara',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Tangalle',
    city: 'Tangalle',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Nuwara Eliya',
    city: 'Nuwara Eliya',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDTHM (Tourism and Hospitality Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Trincomalee',
    city: 'Trincomalee',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HNDM (Management)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Vavuniya',
    city: 'Vavuniya',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HND English',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'ATI Sammanthurai',
    city: 'Sammanthurai',
    courses: {
      'Higher National Diploma Programmes': [
        'HNDA (Accountancy)',
        'HNDIT (Information Technology)',
        'HND English',
      ],
    },
  ),
];

const List<SriLankanInstitution> sriLankanUniversityColleges = [
  SriLankanInstitution(
    name: 'Sri Lanka Institute of Information Technology (SLIIT)',
    city: 'Malabe',
    courses: {
      'Faculty of Computing': [
        'BSc in Information Technology',
        'BSc in Information Technology (Software Engineering)',
        'BSc in Information Technology (Data Science)',
        'BSc in Information Technology (Cyber Security)',
        'BSc in Information Technology (Artificial Intelligence)',
        'BSc in Information Technology (Networking)',
      ],
      'Faculty of Engineering': [
        'BSc in Computer Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering (Hons)',
      ],
      'Faculty of Graduate Studies': [
        'BSc in Information Technology (Special)',
        'MBA in Information Technology',
      ],
      'Faculty of Humanities and Sciences': [
        'BA in English',
        'BSc in Biological Sciences',
        'BSc in Physical Sciences',
      ],
      'School of Architecture': [
        'BArch (Hons) in Architecture',
        'BSc in Quantity Surveying',
      ],
      'SLIIT Business School': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Marketing',
        'BSc in Human Resource Management',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'National Institute of Business Management (NIBM)',
    city: 'Colombo',
    courses: {
      'Faculty of Business Administration': [
        'BSc (Hons) in Business Administration',
        'MBA',
        'Postgraduate Diploma in Business Administration',
      ],
      'Faculty of Management Studies': [
        'BSc in Human Resource Management',
        'BSc in Marketing',
        'BSc in Operations Management',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'NSBM Green University',
    city: 'Colombo',
    courses: {
      'Faculty of Business': [
        'BSc in Business Administration',
        'BSc in International Business',
        'BSc in Accounting and Finance',
      ],
      'Faculty of Computing': [
        'BSc in Information Technology',
        'BSc in Data Science',
      ],
      'Faculty of Engineering': [
        'BSc in Civil Engineering',
        'BSc in Electrical and Electronic Engineering',
      ],
      'Faculty of Science': [
        'BSc in Biological Science',
        'BSc in Physical Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Sri Lanka Institute of Development Administration (SLIDA)',
    city: 'Colombo',
    courses: {
      'Public and Financial Management': [
        'BA in Public Administration',
        'BA in Financial Management',
        'Postgraduate Diploma in Public Administration',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Institute of Surveying and Mapping',
    city: 'Colombo',
    courses: {
      'Surveying and Mapping': [
        'BSc in Surveying Science',
        'BSc in Geoinformatics',
        'BSc in Surveying and Geomatics',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'National Institute of Social Development',
    city: 'Colombo',
    courses: {
      'Social Development': [
        'BA in Social Work',
        'BA (Hons) in Applied Communication and Media Technology',
        'BA (Hons) in Applied Archaeology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Colombo International Nautical and Engineering College (CINEC)',
    city: 'Colombo',
    courses: {
      'Engineering': [
        'BSc (Hons) in Marine Engineering',
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering',
      ],
      'Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
      ],
      'Logistics and Transport': [
        'BSc (Hons) in Logistics and Transportation',
        'BSc in Supply Chain Management',
      ],
      'Maritime Studies': [
        'BSc (Hons) in Maritime Science',
        'BSc in Nautical Studies',
        'BSc in Marine Engineering',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'South Asian Institute of Technology and Medicine (SAITM)',
    city: 'Kelaniya',
    courses: {
      'Biosystems Technology': [
        'BSc in Biosystems Technology',
        'BSc in Medical Laboratory Science',
      ],
      'Engineering': [
        'BSc in Electrical and Electronic Engineering',
        'BSc in Computer Engineering',
      ],
      'Medicine and Allied Sciences': [
        'MBBS',
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Aquinas College of Higher Studies',
    city: 'Colombo',
    courses: {
      'Arts and Religious Studies': [
        'BA in Arts',
        'BA in Religious Studies',
        'BA in Buddhist Studies',
      ],
      'Education': ['BA in Education', 'BEd (Hons) in Education'],
      'Information Technology': [
        'BSc in Information Technology',
        'BSc in Software Engineering',
      ],
      'Psychology and Counselling': [
        'BA in Psychology',
        'BSc in Psychology and Counselling',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Sri Lanka International Buddhist Academy (SIBA)',
    city: 'Pallekele',
    courses: {
      'Buddhist Studies': [
        'BA in Buddhist Studies',
        'BA in Pali Studies',
        'BA in Buddhist Leadership',
      ],
      'Business Management': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
      ],
      'Information Technology': [
        'BSc in Information Technology',
        'BSc in Data Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Nagananda International Institute for Buddhist Studies',
    city: 'Colombo',
    courses: {
      'Buddhist Studies': [
        'BA in Buddhist Studies',
        'BA in Pali Studies',
        'BA in Comparative Religion',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Horizon Campus',
    city: 'Colombo',
    courses: {
      'Biotechnology': ['BSc in Biotechnology', 'BSc in Biomedical Science'],
      'Business': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Marketing',
      ],
      'Education': ['BA in Education', 'BEd (Hons) in Education'],
      'Engineering': [
        'BSc in Information Technology',
        'BSc in Software Engineering',
        'BSc in Electrical and Electronic Engineering',
      ],
      'Information Technology': [
        'BSc in Information Technology',
        'BSc in Data Science',
      ],
      'Nursing and Healthcare': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Sri Lanka Technological Campus (SLTC)',
    city: 'Colombo',
    courses: {
      'Faculty of Technology': [
        'BSc in Information Technology',
        'BSc in Software Engineering',
        'BSc in Data Science',
      ],
      'School of Engineering': [
        'BSc in Electrical and Electronic Engineering',
        'BSc in Mechanical Engineering',
        'BSc in Civil Engineering',
      ],
      'School of Business': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Human Resource Management',
      ],
      'School of Design': [
        'BA (Hons) in Fashion Design',
        'BA (Hons) in Graphic Design',
      ],
      'School of Science': [
        'BSc in Biological Science',
        'BSc in Physical Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Sri Lanka Institute of Nanotechnology (SLINTEC)',
    city: 'Homagama',
    courses: {
      'Nanoscience and Nanotechnology': [
        'BSc in Nanoscience and Nanotechnology',
        'BSc in Nanotechnology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Saegis Campus',
    city: 'Colombo',
    courses: {
      'Business': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Marketing',
      ],
      'Information Technology': [
        'BSc in Information Technology',
        'BSc in Software Engineering',
        'BSc in Data Analytics',
      ],
      'Nursing and Healthcare': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'International College of Business and Technology (ICBT)',
    city: 'Colombo',
    courses: {
      'Business': [
        'BSc in Business Administration (Hons)',
        'BSc in Accounting and Finance',
        'BSc in Marketing',
      ],
      'Engineering': [
        'BSc in Information Technology',
        'BSc in Software Engineering',
        'BSc in Electrical and Electronic Engineering',
      ],
      'Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
      ],
      'Humanities': ['BA in Arts', 'BA in English'],
      'Information Technology': [
        'BSc in Information Technology',
        'BSc in Data Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Business Management School (BMS)',
    city: 'Colombo',
    courses: {
      'Accounting and Finance': [
        'BSc in Accounting and Finance',
        'BSc in Business Administration',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'International Institute of Health Sciences (IIHS)',
    city: 'Colombo',
    courses: {
      'Health Sciences': [
        'BSc in Nursing',
        'BSc in Medical Laboratory Science',
        'BSc in Physiotherapy',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Lanka Nippon BizTech Institute',
    city: 'Colombo',
    courses: {
      'Business and Technology': [
        'BSc (Hons) in Software Engineering',
        'BSc (Hons) in Information Technology',
        'BSc in Business Analytics',
        'BSc in Data Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Gateway College',
    city: 'Colombo',
    courses: {
      'Education': ['BA (Hons) in Education', 'BEd (Hons) in Education'],
      'Information Technology': [
        'BSc in Information Technology',
        'BSc in Data Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'The Lyceum Campus',
    city: 'Colombo',
    courses: {
      'Education': [
        'BA (Hons) in Education',
        'BEd (Hons) in Primary Education',
      ],
      'Business Administration': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Sri Lanka Institute of Chemistry',
    city: 'Colombo',
    courses: {
      'Chemical Sciences': [
        'BSc (Hons) in Chemical Science',
        'BSc in Applied Chemistry',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Royal Institute of Colombo',
    city: 'Colombo',
    courses: {
      'Business and Finance': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
        'BSc in Economics and Finance',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Institute of Chartered Accountants of Sri Lanka',
    city: 'Colombo',
    courses: {
      'Accounting': ['BA (Hons) in Accountancy', 'BSc in Applied Accounting'],
    },
  ),
  SriLankanInstitution(
    name: 'SANASA Campus',
    city: 'Colombo',
    courses: {
      'Banking and Finance': [
        'BSc in Banking and Finance',
        'BSc in Insurance and Risk Management',
        'BSc in Regional Science and Planning',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'KAATSU International University',
    city: 'Colombo',
    courses: {
      'Biomedical Science': [
        'BSc in Biomedical Science',
        'BSc in Medical Laboratory Science',
      ],
      'Business Management': [
        'BSc in Business Administration',
        'BSc in Accounting and Finance',
      ],
      'Education': ['BA (Hons) in Education'],
      'Nursing': ['BSc in Nursing'],
      'Medical Sciences': ['MBBS', 'BSc in Physiotherapy'],
    },
  ),
  SriLankanInstitution(
    name: 'ESOFT Metro Campus',
    city: 'Colombo',
    courses: {
      'Business and Technology': [
        'BSc in Information Technology',
        'BSc in Business Administration',
        'BSc in Data Science',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'Benedict XVI Catholic Institute of Higher Education',
    city: 'Colombo',
    courses: {
      'Business and Technology': [
        'BSc in Business Administration',
        'BSc in Information Technology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University College of Ratmalana (UCR)',
    city: 'Ratmalana',
    courses: {
      'NVQ Level 5 and 6 Programmes': [
        'Fashion Design Technology',
        'Event Management',
        'Hospitality Management',
        'Travel & Tour Management',
        'Telecommunication Technology',
        'Electrical Technology',
        'Television Post-Production Technology',
        'Television Program Production Technology',
        'Print Media Production Technology',
        'Cosmetology (Beauty Culture)',
        'Food Technology',
        'Building Services Technology',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University College of Matara (UCM)',
    city: 'Matara',
    courses: {
      'NVQ Level 5 and 6 Programmes': [
        'Automobile Technology',
        'Building Services Technology',
        'Cosmetology',
        'Event Management',
        'Food Technology',
        'Hospitality Management',
        'Quantity Surveying Technology',
        'Refrigeration & Air Conditioning Technology',
        'Travel & Tour Management',
        'Aquaculture & Aquatic Resources Management',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University College of Jaffna (UCJ)',
    city: 'Jaffna',
    courses: {
      'NVQ Level 5 and 6 Programmes': [
        'Building Services Technology',
        'Construction Technology',
        'Cosmetology',
        'Electrical Technology',
        'Hospitality Management',
        'Mechatronics Technology',
        'Production Technology',
        'Quantity Surveying Technology',
        'Travel & Tour Management',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University College of Anuradhapura (UCA)',
    city: 'Anuradhapura',
    courses: {
      'NVQ Level 5 and 6 Programmes': [
        'Drafting Technology',
        'Electronic Technology',
        'Farm Machinery Technology',
        'Hospitality Management',
        'Mechatronics Technology',
        'Building Services Technology',
        'Travel & Tour Management',
        'Aquaculture & Aquatic Resources Management',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University College of Kuliyapitiya (UCK)',
    city: 'Kuliyapitiya',
    courses: {
      'NVQ Level 5 and 6 Programmes': [
        'Automobile Technology',
        'Construction Technology',
        'Drafting Technology',
        'Electronic Technology',
        'Hospitality Management',
        'Mechatronics Technology',
        'Quantity Surveying Technology',
        'Refrigeration & Air Conditioning Technology',
        'Travel & Tour Management',
        'Aquaculture & Aquatic Resources Management',
      ],
    },
  ),
  SriLankanInstitution(
    name: 'University College of Batangala (UCB - Ratnapura)',
    city: 'Ratnapura',
    courses: {
      'NVQ Level 5 and 6 Programmes': [
        'Post Harvest Technology',
        'Food Technology',
        'Hospitality Management',
        'Travel & Tour Management',
        'Farm Machinery Technology',
        'Plant Production Technology',
      ],
    },
  ),
];

const List<SriLankanInstitution> sriLankanInstitutions = [
  ...sriLankanStateUniversities,
  ...sriLankanUniversityColleges,
  ...sriLankanTechnologicalInstitutes,
];

final Map<String, SriLankanInstitution> sriLankanInstitutionsByName = {
  for (final institution in sriLankanInstitutions)
    institution.name: institution,
};

final Map<String, List<String>> sriLankanInstitutionFaculties = {
  for (final institution in sriLankanInstitutions)
    institution.name: institution.faculties,
};

final Map<String, Map<String, List<String>>> sriLankanInstitutionCourses = {
  for (final institution in sriLankanInstitutions)
    institution.name: institution.courses,
};

final Map<String, UniversityKind> sriLankanInstitutionKinds = {
  for (final institution in sriLankanStateUniversities)
    institution.name: UniversityKind.stateUniversity,
  for (final institution in sriLankanUniversityColleges)
    institution.name: UniversityKind.universityCollege,
  for (final institution in sriLankanTechnologicalInstitutes)
    institution.name: UniversityKind.advancedTechnologicalInstitute,
};

SriLankanInstitution? institutionFor(String universityName) =>
    sriLankanInstitutionsByName[universityName.trim()];

UniversityKind? universityKindFor(String universityName) =>
    sriLankanInstitutionKinds[universityName.trim()];

String universityCityFor(String universityName) =>
    institutionFor(universityName)?.city ?? '';

bool isCatalogInstitution(String universityName) =>
    sriLankanInstitutionsByName.containsKey(universityName.trim());

List<String> catalogCoursesFor(String universityName, String facultyName) {
  final courses =
      sriLankanInstitutionCourses[universityName.trim()]?[facultyName.trim()];
  if (courses == null) return const [];
  return List.unmodifiable(List<String>.of(courses)..sort());
}

int get sriLankanStateUniversityCount => sriLankanStateUniversities.length;

int get sriLankanTechnologicalInstituteCount =>
    sriLankanTechnologicalInstitutes.length;

int get sriLankanUniversityCollegeCount => sriLankanUniversityColleges.length;
