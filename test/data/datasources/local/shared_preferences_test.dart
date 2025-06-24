import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatgram/data/datasources/local/shared_preferences_local_data_source.dart';
import 'package:fatgram/core/storage/secure_storage_service.dart';
import '../../../test_helper.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late SharedPreferencesLocalDataSource dataSource;
  late MockSharedPreferences mockSharedPreferences;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockSecureStorageService = MockSecureStorageService();
    dataSource = SharedPreferencesLocalDataSource(
      sharedPreferences: mockSharedPreferences,
      secureStorageService: mockSecureStorageService,
    );
  });

  group('SharedPreferencesLocalDataSource', () {
    group('ユーザーデータの管理', () {
      test('should save user data successfully', () async {
        // Arrange
        final userData = TestHelper.generateUserData();
        when(() => mockSharedPreferences.setString(any(), any()))
            .thenAnswer((_) async => true);

        // Act
        await dataSource.saveUserData(userData);

        // Assert
        verify(() => mockSharedPreferences.setString(
          'user_data',
          any(that: contains(userData['id'])),
        )).called(1);
      });

      test('should retrieve user data successfully', () async {
        // Arrange
        final userData = TestHelper.generateUserData();
        final userDataJson = '''
        {
          "id": "${userData['id']}",
          "name": "${userData['name']}",
          "email": "${userData['email']}",
          "age": ${userData['age']},
          "weight": ${userData['weight']},
          "height": ${userData['height']},
          "createdAt": "${userData['createdAt']}"
        }
        ''';
        when(() => mockSharedPreferences.getString('user_data'))
            .thenReturn(userDataJson);

        // Act
        final result = await dataSource.getUserData();

        // Assert
        expect(result, isNotNull);
        expect(result!['id'], equals(userData['id']));
        expect(result['name'], equals(userData['name']));
        expect(result['email'], equals(userData['email']));
      });

      test('should return null when user data does not exist', () async {
        // Arrange
        when(() => mockSharedPreferences.getString('user_data'))
            .thenReturn(null);

        // Act
        final result = await dataSource.getUserData();

        // Assert
        expect(result, isNull);
      });

      test('should clear user data successfully', () async {
        // Arrange
        when(() => mockSharedPreferences.remove('user_data'))
            .thenAnswer((_) async => true);

        // Act
        await dataSource.clearUserData();

        // Assert
        verify(() => mockSharedPreferences.remove('user_data')).called(1);
      });
    });

    group('認証トークンの管理', () {
      test('should save auth token securely', () async {
        // Arrange
        const token = 'test-auth-token';
        when(() => mockSecureStorageService.write(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await dataSource.saveAuthToken(token);

        // Assert
        verify(() => mockSecureStorageService.write('auth_token', token))
            .called(1);
      });

      test('should retrieve auth token securely', () async {
        // Arrange
        const token = 'test-auth-token';
        when(() => mockSecureStorageService.read('auth_token'))
            .thenAnswer((_) async => token);

        // Act
        final result = await dataSource.getAuthToken();

        // Assert
        expect(result, equals(token));
        verify(() => mockSecureStorageService.read('auth_token')).called(1);
      });

      test('should clear auth token securely', () async {
        // Arrange
        when(() => mockSecureStorageService.delete('auth_token'))
            .thenAnswer((_) async {});

        // Act
        await dataSource.clearAuthToken();

        // Assert
        verify(() => mockSecureStorageService.delete('auth_token')).called(1);
      });
    });

    group('設定値の管理', () {
      test('should save app settings successfully', () async {
        // Arrange
        final settings = {
          'theme': 'dark',
          'notifications': true,
          'language': 'ja',
          'units': 'metric',
        };
        when(() => mockSharedPreferences.setString(any(), any()))
            .thenAnswer((_) async => true);

        // Act
        await dataSource.saveSettings(settings);

        // Assert
        verify(() => mockSharedPreferences.setString(
          'app_settings',
          any(that: contains('dark')),
        )).called(1);
      });

      test('should retrieve app settings successfully', () async {
        // Arrange
        const settingsJson = '''
        {
          "theme": "dark",
          "notifications": true,
          "language": "ja",
          "units": "metric"
        }
        ''';
        when(() => mockSharedPreferences.getString('app_settings'))
            .thenReturn(settingsJson);

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result, isNotNull);
        expect(result!['theme'], equals('dark'));
        expect(result['notifications'], equals(true));
        expect(result['language'], equals('ja'));
      });

      test('should return default settings when none exist', () async {
        // Arrange
        when(() => mockSharedPreferences.getString('app_settings'))
            .thenReturn(null);

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result, isNotNull);
        expect(result!['theme'], equals('light'));
        expect(result['notifications'], equals(true));
        expect(result['language'], equals('en'));
      });
    });

    group('個別設定の管理', () {
      test('should save and retrieve string setting', () async {
        // Arrange
        const key = 'test_string';
        const value = 'test_value';
        when(() => mockSharedPreferences.setString(key, value))
            .thenAnswer((_) async => true);
        when(() => mockSharedPreferences.getString(key))
            .thenReturn(value);

        // Act
        await dataSource.setString(key, value);
        final result = dataSource.getString(key);

        // Assert
        expect(result, equals(value));
        verify(() => mockSharedPreferences.setString(key, value)).called(1);
      });

      test('should save and retrieve bool setting', () async {
        // Arrange
        const key = 'test_bool';
        const value = true;
        when(() => mockSharedPreferences.setBool(key, value))
            .thenAnswer((_) async => true);
        when(() => mockSharedPreferences.getBool(key))
            .thenReturn(value);

        // Act
        await dataSource.setBool(key, value);
        final result = dataSource.getBool(key);

        // Assert
        expect(result, equals(value));
        verify(() => mockSharedPreferences.setBool(key, value)).called(1);
      });

      test('should save and retrieve int setting', () async {
        // Arrange
        const key = 'test_int';
        const value = 42;
        when(() => mockSharedPreferences.setInt(key, value))
            .thenAnswer((_) async => true);
        when(() => mockSharedPreferences.getInt(key))
            .thenReturn(value);

        // Act
        await dataSource.setInt(key, value);
        final result = dataSource.getInt(key);

        // Assert
        expect(result, equals(value));
        verify(() => mockSharedPreferences.setInt(key, value)).called(1);
      });

      test('should save and retrieve double setting', () async {
        // Arrange
        const key = 'test_double';
        const value = 3.14;
        when(() => mockSharedPreferences.setDouble(key, value))
            .thenAnswer((_) async => true);
        when(() => mockSharedPreferences.getDouble(key))
            .thenReturn(value);

        // Act
        await dataSource.setDouble(key, value);
        final result = dataSource.getDouble(key);

        // Assert
        expect(result, equals(value));
        verify(() => mockSharedPreferences.setDouble(key, value)).called(1);
      });
    });

    group('データクリア機能', () {
      test('should clear all data successfully', () async {
        // Arrange
        when(() => mockSharedPreferences.clear())
            .thenAnswer((_) async => true);
        when(() => mockSecureStorageService.deleteAll())
            .thenAnswer((_) async {});

        // Act
        await dataSource.clearAll();

        // Assert
        verify(() => mockSharedPreferences.clear()).called(1);
        verify(() => mockSecureStorageService.deleteAll()).called(1);
      });

      test('should check if key exists', () {
        // Arrange
        const key = 'test_key';
        when(() => mockSharedPreferences.containsKey(key))
            .thenReturn(true);

        // Act
        final result = dataSource.containsKey(key);

        // Assert
        expect(result, isTrue);
        verify(() => mockSharedPreferences.containsKey(key)).called(1);
      });

      test('should remove specific key', () async {
        // Arrange
        const key = 'test_key';
        when(() => mockSharedPreferences.remove(key))
            .thenAnswer((_) async => true);

        // Act
        await dataSource.remove(key);

        // Assert
        verify(() => mockSharedPreferences.remove(key)).called(1);
      });
    });

    group('エラーハンドリング', () {
      test('should handle JSON parsing error gracefully', () async {
        // Arrange
        when(() => mockSharedPreferences.getString('user_data'))
            .thenReturn('invalid json');

        // Act
        final result = await dataSource.getUserData();

        // Assert
        expect(result, isNull);
      });

      test('should handle SharedPreferences exception', () async {
        // Arrange
        when(() => mockSharedPreferences.setString(any(), any()))
            .thenThrow(Exception('SharedPreferences error'));

        // Act & Assert
        expect(
          () => dataSource.saveUserData({'id': 'test'}),
          throwsException,
        );
      });

      test('should handle SecureStorage exception', () async {
        // Arrange
        when(() => mockSecureStorageService.write(any(), any()))
            .thenThrow(Exception('SecureStorage error'));

        // Act & Assert
        expect(
          () => dataSource.saveAuthToken('token'),
          throwsException,
        );
      });
    });
  });
}