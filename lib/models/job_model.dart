class Job {
  final String id;
  final String title;
  final String company;
  final String logoUrl;
  final String description;
  final String location;
  final String salary;
  final String datePosted;
  final String source;
  final String applyLink;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.logoUrl,
    required this.description,
    required this.location,
    required this.salary,
    required this.datePosted,
    required this.source,
    required this.applyLink,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown',
      company: json['company'] ?? 'Unknown',
      logoUrl: json['logoUrl'] ?? '',
      description: json['description'] ?? 'No description available.',
      location: json['location'] ?? 'Unknown location',
      salary: json['salary'] ?? 'Not specified',
      datePosted: json['datePosted'] ?? 'Not Available',
      source: json['source'] ?? 'Unknown source',
      applyLink: json['applyLink'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'logoUrl': logoUrl,
      'description': description,
      'location': location,
      'salary': salary,
      'datePosted': datePosted,
      'source': source,
      'applyLink': applyLink,
    };
  }
}

// Sample job data for testing
List<Job> sampleJobs = [
  Job(
    id: 'sample-1',
    title: 'Flutter Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain Flutter applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    datePosted: '2 days ago',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
  Job(
    id: 'sample-2',
    title: 'Backend Engineer',
    company: 'CodeWorks',
    logoUrl: 'https://example.com/logo2.png',
    description: 'Work on scalable backend systems.',
    location: 'San Francisco, CA',
    salary: '\$90,000 - \$120,000',
    datePosted: '1 week ago',
    source: 'Indeed',
    applyLink: 'https://example.com/apply2',
  ),
  Job(
    id: 'sample-3',
    title: 'Software Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    datePosted: '3 hours ago',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
];
