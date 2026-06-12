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

  List<TagModel> get tags => model.flattenTags;

  /// Busca un tag DICOM por su código hexadecimal (ej: "0010,0010")
  /// en la lista aplanada de tags (flattenTags).
  String? _getTagByHex(String hex) {
    final tag = tags.cast<TagModel?>().firstWhere(
          (t) => t?.getTag() == hex,
          orElse: () => null,
        );
    return tag?.value;
  }

  String? get modality => _getTagByHex('0008,0060') ?? model.getModality();
  String? get patientName => _getTagByHex('0010,0010') ?? model.getPatientName();
  String? get patientId => _getTagByHex('0010,0020');
  String? get studyDescription => _getTagByHex('0008,1030');
  String? get studyDate => _getTagByHex('0008,0020');
  String? get seriesDescription => _getTagByHex('0008,103e') ?? model.getSeriesDescription();
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
