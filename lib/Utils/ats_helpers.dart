import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:doc_text/doc_text.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

class ATSHelper {
  // PDF Extraction
  Future<String?> extractTextFromPdf(String filePath) async {
    try {
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();
      return text;
    } catch (e) {
      print("Error extracting text from PDF: $e");
      return null;
    }
  }

  Future<String?> extractTextFromPdfSimple(String filePath) async {
    try {
      final PDFDoc? doc = await PDFDoc.fromFile(File(filePath));
      return doc?.text;
    } catch (e) {
      print("Error extracting text from PDF (simple): $e");
      return null;
    }
  }

  // Word Extraction
  Future<String?> extractTextFromWord(String filePath) async {
    try {
      final String? extractedText = await DocText().extractTextFromDoc(
        filePath,
      );
      return extractedText;
    } catch (e) {
      print("Error extracting text from Word: $e");
      return null;
    }
  }

  Future<String?> extractName(String text) async {
    try {
      final entityExtractor = EntityExtractor(
        language: EntityExtractorLanguage.english,
      );
      final entities = await entityExtractor.annotateText(text);
      await entityExtractor.close();

      for (final entity in entities) {
        if (entity.entities.isNotEmpty &&
            entity.entities.first.rawValue == "PERSON") {
          return entity.text;
        }
      }

      // Fallback to regex if ML Kit fails
      final nameRegex = RegExp(r'\b[A-Z][a-z]+\s[A-Z][a-z]+\b');
      final match = nameRegex.firstMatch(text);
      return match?.group(0);
    } catch (e) {
      print("Error extracting name: $e");
      return null;
    }
  }

  // Email Extraction
  List<String> extractEmailAddresses(String text) {
    final emailRegex = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final matches = emailRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  // Section Extraction
  String extractSection(String text, List<String> sectionHeadings) {
    for (final heading in sectionHeadings) {
      final index = text.toLowerCase().indexOf(heading.toLowerCase());
      if (index != -1) {
        final nextHeadingIndex = _findNextHeadingIndex(
          text,
          index + heading.length,
        );
        if (nextHeadingIndex != -1) {
          return text
              .substring(index + heading.length, nextHeadingIndex)
              .trim();
        } else {
          return text.substring(index + heading.length).trim();
        }
      }
    }
    return ""; // Return empty string if no section found
  }

  int _findNextHeadingIndex(String text, int startIndex) {
    final headings = [
      "education",
      "academic history",
      "qualifications",
      "work experience",
      "professional experience",
      "experience",
      "employment history",
      "work history",
    ];

    int minIndex = -1;
    for (final heading in headings) {
      final index = text.toLowerCase().indexOf(heading, startIndex);
      if (index != -1 && (minIndex == -1 || index < minIndex)) {
        minIndex = index;
      }
    }
    return minIndex;
  }

  // Education Extraction
  String extractEducation(String text) {
    final educationHeadings = [
      "education",
      "academic history",
      "qualifications",
    ];
    return extractSection(text, educationHeadings);
  }

  // Work Experience Extraction
  String extractWorkExperience(String text) {
    final workExperienceHeadings = [
      "work experience",
      "professional experience",
      "experience",
      "employment history",
      "work history",
    ];
    return extractSection(text, workExperienceHeadings);
  }
}
