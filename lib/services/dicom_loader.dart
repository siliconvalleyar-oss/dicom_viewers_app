import 'dart:io';
import 'dart:typed_data';
import 'package:dicom_parser/dicom_parser.dart';

class DicomStudyFile {
  final String fileName;
  final String? filePath;
  final DICOMModel model;
  final Uint8List imageBytes;

  DicomStudyFile({
    required this.fileName,
    this.filePath,
    required this.model,
    required this.imageBytes,
  });

  String? get modality => model.getModality();
  String? get patientName => model.getPatientName();
  String? get seriesDescription => model.getSeriesDescription();
  List<TagModel> get tags => model.flattenTags;

  String? getTagValue(String description) {
    final tag = tags.where(
      (t) => t.tagDescription.toLowerCase() == description.toLowerCase(),
    );
    return tag.isNotEmpty ? tag.first.value : null;
  }

  String? get patientId => getTagValue('Patient ID');
  String? get studyDescription => getTagValue('Study Description');
  String? get studyDate => getTagValue('Study Date');
}

class DicomLoader {
  final DICOMParser _parser = DICOMParser();

  Future<DicomStudyFile?> loadFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return _parseBytes(bytes, filePath, file.uri.pathSegments.last);
    } catch (e) {
      return null;
    }
  }

  Future<DicomStudyFile?> loadFromBytes({
    required Uint8List bytes,
    required String name,
  }) async {
    return _parseBytes(bytes, null, name);
  }

  Future<DicomStudyFile?> _parseBytes(
    Uint8List bytes,
    String? filePath,
    String fileName,
  ) async {
    final model = await _parser.parseDICOMFile(bytes);
    if (model == null || model.imageBytes == null) return null;
    return DicomStudyFile(
      fileName: fileName,
      filePath: filePath,
      model: model,
      imageBytes: model.imageBytes!,
    );
  }
}
