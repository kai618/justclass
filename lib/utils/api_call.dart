import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:justclass/models/class_details_data.dart';
import 'package:justclass/models/member.dart';
import 'package:justclass/models/note.dart';
import 'package:justclass/models/user.dart';
import 'package:justclass/providers/class.dart';
import 'package:justclass/utils/http_exception.dart';
import 'package:justclass/widgets/create_class_form.dart';
import 'package:mime/mime.dart';

class ApiCall {
  static const _headers = {'Content-type': 'application/json', 'Accept': 'application/json'};

  static checkInternetConnection() {
    // TODO: check internet
  }

  static Future<bool> postUserData(User user) async {
    try {
      checkInternetConnection();
      const url = 'https://justclass-da0b0.appspot.com/api/v1/user';
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'localId': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoUrl': user.photoUrl,
        }),
      );
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to update user data! ${response.statusCode}.');

      final isNew = json.decode(response.body)['newUser'];
      return isNew;
    } catch (error) {
      throw error;
    }
  }

  static Future<Class> createClass(String uid, CreateClassFormData data) async {
    try {
      await Future.delayed(Duration(seconds: 5));
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/$uid';
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'title': data.title,
          'section': data.section,
          'subject': data.subject,
          'room': data.room,
          'theme': data.theme,
        }),
      );
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to create new class! ${response.statusCode}');

      final info = json.decode(response.body);
      final newClass = Class.fromJson(info);

      return newClass;
    } catch (error) {
      throw error;
    }
  }

  static Future<List<Class>> fetchClassList(String uid) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/$uid';
      final response = await http.get(url, headers: _headers);
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to fetch class data! ${response.statusCode}');

      final List<Class> classList = [];
      final classesData = json.decode(response.body) as List<dynamic>;
      classesData.forEach((cls) => classList.add(Class.fromJson(cls)));
      return classList;
    } catch (error) {
      throw error;
    }
  }

  static Future<Class> joinClassWithCode(String uid, String publicCode) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/$uid/$publicCode';
      final response = await http.put(url, headers: _headers);
      if (response.statusCode == 417)
        throw HttpException(message: 'Class code does not exist!');
      else if (response.statusCode >= 400) throw HttpException(message: 'Unable to join class! ${response.statusCode}');

      final data = json.decode(response.body);
      return Class.fromJson(data);
    } catch (error) {
      throw error;
    }
  }

  static Future<void> removeOwnedClass(String uid, String cid) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/$uid/$cid';
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode >= 400) throw HttpException(message: 'Unable to remove class! ${response.statusCode}');
    } catch (error) {
      throw error;
    }
  }

  static Future<void> updateClassDetails(String uid, String cid, ClassDetailsData data) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/$uid';
      final response = await http.patch(url,
          headers: _headers,
          body: json.encode({
            'classroomId': cid,
            'title': data.title,
            'subject': data.subject,
            'section': data.section,
            'room': data.room,
            'theme': data.theme,
            'description': data.description,
            'studentsNotePermission': data.permissionCode.name,
          }));
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to update class info! ${response.statusCode}');
    } catch (error) {
      throw error;
    }
  }

  static Future<String> requestNewPublicCode(String uid, String cid) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/$uid?requestNewPublicCode=true';
      final response = await http.patch(
        url,
        headers: _headers,
        body: json.encode({'classroomId': cid}),
      );
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to generate new class code! ${response.statusCode}');
      final newCode = json.decode(response.body)['publicCode'];
      return newCode;
    } catch (error) {
      throw error;
    }
  }

  static Future<Class> fetchClassDetails(String cid) async {
    try {
      checkInternetConnection();
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Implementation for class info screen in student mode
    } catch (error) {
      throw error;
    }
  }

  static Future<List<Member>> fetchMemberList(String uid, String cid) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/members/$uid/$cid';
      final response = await http.get(url, headers: _headers);
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to fetch member list! ${response.statusCode}');

      final memberData = json.decode(response.body) as List<dynamic>;
      final members = memberData
          .map((m) => Member(
                uid: m['localId'],
                photoUrl: m['photoUrl'],
                displayName: m['displayName'],
                joinDatetime: m['joinDatetime'],
                role: ClassRoles.getType(m['role']),
              ))
          .toList();

      // for testing purpose only
//      members
//        ..addAll([
//          Member(
//            displayName: 'Bot 1',
//            uid: '2',
//            role: ClassRole.COLLABORATOR,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/131/131',
//          ),
//          Member(
//            displayName: 'Bot 1',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/162/162',
//          ),
//          Member(
//            displayName: 'Bot 2',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/149/149',
//          ),
//          Member(
//            displayName: 'Bot 3',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: null,
//          ),
//          Member(
//            displayName: 'Bot 4',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/153/153',
//          ),
//          Member(
//            displayName: 'Bot 5',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/144/144',
//          ),
//          Member(
//            displayName: 'Bot 6',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/154/154',
//          ),
//          Member(
//            displayName: 'Bot 7',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/155/155',
//          ),
//          Member(
//            displayName: 'Bot 8',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/156/156',
//          ),
//          Member(
//            displayName: 'A Bot 9',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: null,
//          ),
//          Member(
//            displayName: 'Bot 10',
//            uid: '1',
//            role: ClassRole.STUDENT,
//            joinDatetime: 123,
//            photoUrl: 'https://placekitten.com/110/110',
//          )
//        ]);
      return members;
    } catch (error) {
      throw error;
    }
  }

  static Future<void> removeCollaborator() async {
    await Future.delayed(Duration(seconds: 1));
    throw HttpException(message: 'Collab cannot be removed');
  }

  static Future<void> removeStudent() async {
    await Future.delayed(Duration(seconds: 1));
    throw HttpException(message: 'Student cannot be removed');
  }

  static Future<List<Member>> fetchSuggestedMembers(
    String uid,
    String cid,
    ClassRole role,
    String keyword,
  ) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/lookup/$uid/$cid/${role.name}?keyword=$keyword';
      final response = await http.get(url, headers: _headers);
      if (response.statusCode >= 400) throw HttpException(message: 'Unable to suggest users! ${response.statusCode}');

      final memberData = json.decode(response.body) as List<dynamic>;
      final members = memberData
          .map((u) => Member(
                uid: u['uid'],
                email: u['email'],
                displayName: u['displayName'],
                photoUrl: u['photoUrl'],
              ))
          .toList();

      // for testing purpose only
//      members.addAll([
//        Member(
//          uid: '1',
//          email: 'test@gmail.com',
//          displayName: 'Test',
//          photoUrl: 'https://placekitten.com/100/100',
//        ),
//        Member(
//          uid: '2',
//          email: 'bot@hsu.com',
//          displayName: 'Bot',
//          photoUrl: 'https://placekitten.com/101/101',
//        ),
//      ]);

      return members;
    } catch (error) {
      throw error;
    }
  }

  static Future<void> inviteMembers(String uid, String cid, Set<String> emails, ClassRole role) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/$uid/$cid';

      final response = await http.patch(
        url,
        headers: _headers,
        body: json.encode([
          ...emails.map((e) => {'email': e, 'role': role.name}),
        ]),
      );
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to send invitations! ${response.statusCode}');
    } catch (error) {
      throw error;
    }
  }

  static Future<void> leaveCLass(String uid, String cid) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/classroom/leave/$uid/$cid';

      final response = await http.delete(url, headers: _headers);
      if (response.statusCode >= 400) throw HttpException(message: 'Unable to leave class!');
    } catch (error) {
      throw error;
    }
  }

  static Future<dynamic> fetchNotifications(String uid) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/notification/$uid';

      final response = await http.get(url, headers: _headers);
      if (response.statusCode >= 400)
        throw HttpException(message: 'Unable to fetch notifications! ${response.statusCode}');

      final notificationData = json.decode(response.body) as List<dynamic>;
      print(notificationData);
    } catch (error) {
      throw error;
    }
  }

  static Future<void> postNote(String uid, String cid, String content, Map<String, String> files) async {
    try {
      checkInternetConnection();
      final url = 'https://justclass-da0b0.appspot.com/api/v1/note/$uid/$cid';

      // Reference: https://stackoverflow.com/questions/44841729/how-to-upload-image-in-flutter
      final request = http.MultipartRequest('POST', Uri.parse(url))..fields['content'] = content;
      files.forEach((name, path) async {
        final file = await http.MultipartFile.fromPath('attachments', path,
            filename: name, contentType: MediaType(lookupMimeType(path), ''));
        request.files.add(file);
      });
      final response = await request.send();

      if (response.statusCode >= 400) throw HttpException(message: 'Unable to post notes! ${response.statusCode}');

      final byteData = await response.stream.toBytes();
      final strData = String.fromCharCodes(byteData);
      final data = json.decode(strData);

//      return Note();
    } catch (error) {
      throw error;
    }
  }
}
