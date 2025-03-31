class Job {
  final String title;
  final String company;
  final String logoUrl;
  final String description;
  final String location;
  final String salary;
  final String source;
  final String applyLink;

  Job({
    required this.title,
    required this.company,
    required this.logoUrl,
    required this.description,
    required this.location,
    required this.salary,
    required this.source,
    required this.applyLink,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      title: json['title'] ?? 'Unknown',
      company: json['company'] ?? 'Unknown',
      logoUrl: json['logoUrl'] ?? '',
      description: json['description'] ?? 'No description available.',
      location: json['location'] ?? 'Unknown location',
      salary: json['salary'] ?? 'Not specified',
      source: json['source'] ?? 'Unknown source',
      applyLink: json['applyLink'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'logoUrl': logoUrl,
      'description': description,
      'location': location,
      'salary': salary,
      'source': source,
      'applyLink': applyLink,
    };
  }
}

// Sample job data for testing
List<Job> sampleJobs = [
  Job(
    title: 'Flutter Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain Flutter applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
  Job(
    title: 'Backend Engineer',
    company: 'CodeWorks',
    logoUrl: 'https://example.com/logo2.png',
    description: 'Work on scalable backend systems.',
    location: 'San Francisco, CA',
    salary: '\$90,000 - \$120,000',
    source: 'Indeed',
    applyLink: 'https://example.com/apply2',
  ),
  Job(
    title: 'Softwre Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain Flutter applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
  Job(
    title: 'IOS Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain Flutter applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
  Job(
    title: 'Android Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain Flutter applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
  Job(
    title: 'Game Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain Flutter applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
  Job(
    title: 'Building Developer',
    company: 'TechCorp',
    logoUrl: 'https://example.com/logo1.png',
    description: 'Develop and maintain Flutter applications.',
    location: 'Remote',
    salary: '\$80,000 - \$100,000',
    source: 'LinkedIn',
    applyLink: 'https://example.com/apply1',
  ),
];
