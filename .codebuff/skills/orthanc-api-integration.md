# Orthanc API Integration

## API Endpoints
| Endpoint | Description |
|---|---|
| `GET /patients` | List of patient IDs |
| `GET /patients/{id}` | Patient details (MainDicomTags) |
| `GET /studies/{id}` | Study details |
| `GET /series/{id}` | Series details |
| `GET /instances/{id}` | Instance details |
| `GET /instances/{id}/preview` | PNG preview image |
| `GET /instances/{id}/file` | Raw DICOM file |

## Auth
Basic auth: `Authorization: Basic base64(username:password)`

## JSON Response Structure

### Patient
```json
{
  "ID": "...",
  "MainDicomTags": {
    "PatientName": "NAME",
    "PatientID": "123",
    "PatientBirthDate": "19900101",
    "PatientSex": "M"
  },
  "Studies": ["study-id-1", ...]
}
```

> ⚠️ **IMPORTANT**: Orthanc uses `MainDicomTags` (NOT `PatientMainDicomTags`).

### Study
```json
{
  "MainDicomTags": {
    "StudyDescription": "KNEE",
    "StudyDate": "20240115",
    "AccessionNumber": "ACC123"
  },
  "Series": ["series-id-1", ...]
}
```

## Loading Data from Orthanc

```dart
Future<List<OrthancPatient>> getPatients() async {
  final uri = Uri.parse('$baseUrl/patients');
  final response = await http.get(uri, headers: authHeaders);
  final ids = List<String>.from(jsonDecode(response.body));

  final patients = <OrthancPatient>[];
  for (final id in ids) {
    final detail = await _getJson('/patients/$id');
    if (detail != null) {
      patients.add(OrthancPatient.fromJson(id, detail));
    }
  }
  return patients;
}
```

## Data Models Pattern

```dart
class OrthancPatient {
  final String id;
  final String? name;
  final String? patientId;
  final String? birthDate;
  final String? sex;

  factory OrthancPatient.fromJson(String id, Map<String, dynamic> json) {
    final tags = json['MainDicomTags'] as Map<String, dynamic>?;
    return OrthancPatient(
      id: id,
      name: tags?['PatientName']?.toString(),
      patientId: tags?['PatientID']?.toString(),
      birthDate: tags?['PatientBirthDate']?.toString(),
      sex: tags?['PatientSex']?.toString(),
    );
  }
}
```

## Sorting Studies by Date
```dart
studies.sort((a, b) {
  if (a.date == null && b.date == null) return 0;
  if (a.date == null) return 1;
  if (b.date == null) return -1;
  return b.date!.compareTo(a.date!); // newest first
});
```

Date format: YYYYMMDD (string comparison works for sorting)
