import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/services/injector.dart';

/// 設定画面
///
/// アプリの各種設定とプライバシー設定を管理する
/// Material 3デザインの設定画面です。
class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final UserRepository _userRepository;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  User? _user;
  bool _isLoading = true;

  // 設定値
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _progressUpdates = true;
  bool _socialSharing = false;
  bool _dataBackup = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';
  String _selectedUnit = 'Metric';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeServices() {
    _userRepository = Injector().getUserRepository();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 設定を読み込み
  Future<void> _loadSettings() async {
    try {
      _user = await _userRepository.getCurrentUser();
      // TODO: 実際の設定データを読み込み
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 通知設定
                  _buildNotificationSettings(),
                  const SizedBox(height: 16),

                  // 表示設定
                  _buildDisplaySettings(),
                  const SizedBox(height: 16),

                  // プライバシー設定
                  _buildPrivacySettings(),
                  const SizedBox(height: 16),

                  // データ・同期設定
                  _buildDataSettings(),
                  const SizedBox(height: 16),

                  // アプリ情報
                  _buildAppInfo(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  /// ローディング表示
  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 通知設定カード
  Widget _buildNotificationSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchListTile(
              title: 'Enable Notifications',
              subtitle: 'Receive app notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSettings();
              },
            ),
            _buildSwitchListTile(
              title: 'Workout Reminders',
              subtitle: 'Get reminded to stay active',
              value: _workoutReminders,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _workoutReminders = value;
                      });
                      _saveSettings();
                    }
                  : null,
            ),
            _buildSwitchListTile(
              title: 'Progress Updates',
              subtitle: 'Weekly progress summaries',
              value: _progressUpdates,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _progressUpdates = value;
                      });
                      _saveSettings();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// 表示設定カード
  Widget _buildDisplaySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.display_settings_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Display',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchListTile(
              title: 'Dark Mode',
              subtitle: 'Use dark theme',
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
                _saveSettings();
              },
            ),
            _buildDropdownListTile(
              title: 'Language',
              subtitle: 'App language',
              value: _selectedLanguage,
              items: ['English', 'Japanese', 'Spanish', 'French'],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                _saveSettings();
              },
            ),
            _buildDropdownListTile(
              title: 'Units',
              subtitle: 'Measurement units',
              value: _selectedUnit,
              items: ['Metric', 'Imperial'],
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// プライバシー設定カード
  Widget _buildPrivacySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Privacy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchListTile(
              title: 'Social Sharing',
              subtitle: 'Allow sharing achievements',
              value: _socialSharing,
              onChanged: (value) {
                setState(() {
                  _socialSharing = value;
                });
                _saveSettings();
              },
            ),
            _buildActionListTile(
              title: 'Data Privacy',
              subtitle: 'Review privacy policy',
              icon: Icons.policy_outlined,
              onTap: _showPrivacyPolicy,
            ),
            _buildActionListTile(
              title: 'Export Data',
              subtitle: 'Download your data',
              icon: Icons.download_outlined,
              onTap: _exportUserData,
            ),
            _buildActionListTile(
              title: 'Delete Account',
              subtitle: 'Permanently delete account',
              icon: Icons.delete_forever_outlined,
              onTap: _showDeleteAccountDialog,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  /// データ・同期設定カード
  Widget _buildDataSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data & Sync',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchListTile(
              title: 'Auto Backup',
              subtitle: 'Backup data to cloud',
              value: _dataBackup,
              onChanged: (value) {
                setState(() {
                  _dataBackup = value;
                });
                _saveSettings();
              },
            ),
            _buildActionListTile(
              title: 'Sync Now',
              subtitle: 'Manually sync data',
              icon: Icons.sync,
              onTap: _syncData,
            ),
            _buildActionListTile(
              title: 'Storage Usage',
              subtitle: 'View storage details',
              icon: Icons.storage_outlined,
              onTap: _showStorageUsage,
            ),
          ],
        ),
      ),
    );
  }

  /// アプリ情報カード
  Widget _buildAppInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionListTile(
              title: 'Version',
              subtitle: '1.0.0 (Build 1)',
              icon: Icons.info,
              onTap: null,
            ),
            _buildActionListTile(
              title: 'Terms of Service',
              subtitle: 'Read terms of service',
              icon: Icons.description_outlined,
              onTap: _showTermsOfService,
            ),
            _buildActionListTile(
              title: 'Contact Support',
              subtitle: 'Get help and support',
              icon: Icons.support_outlined,
              onTap: _contactSupport,
            ),
            _buildActionListTile(
              title: 'Rate App',
              subtitle: 'Rate FatGram on App Store',
              icon: Icons.star_outline,
              onTap: _rateApp,
            ),
          ],
        ),
      ),
    );
  }

  /// スイッチリストタイル
  Widget _buildSwitchListTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// ドロップダウンリストタイル
  Widget _buildDropdownListTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }

  /// アクションリストタイル
  Widget _buildActionListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? color : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        onTap != null ? Icons.chevron_right : icon,
        color: color.withOpacity(0.6),
      ),
      onTap: onTap,
    );
  }

  /// 設定保存
  void _saveSettings() {
    // TODO: 実際の設定保存処理
    HapticFeedback.lightImpact();
  }

  /// プライバシーポリシー表示
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'FatGram is committed to protecting your privacy. This privacy policy explains how we collect, use, and protect your personal information when you use our app.\n\n'
            '1. Information We Collect:\n'
            '- Health and fitness data\n'
            '- Usage analytics\n'
            '- Account information\n\n'
            '2. How We Use Your Information:\n'
            '- To provide personalized insights\n'
            '- To improve our services\n'
            '- To send relevant notifications\n\n'
            '3. Data Security:\n'
            '- All data is encrypted\n'
            '- We follow industry standards\n'
            '- You control your data\n\n'
            'For the complete privacy policy, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// ユーザーデータエクスポート
  void _exportUserData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Your data will be exported as a JSON file. This may take a few minutes depending on the amount of data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 実際のエクスポート処理
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export started. You will be notified when complete.'),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  /// アカウント削除ダイアログ
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// アカウント削除
  void _deleteAccount() {
    // TODO: 実際の削除処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion initiated. You will receive a confirmation email.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// データ同期
  void _syncData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing data...'),
      ),
    );

    // TODO: 実際の同期処理
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data synced successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  /// ストレージ使用量表示
  void _showStorageUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStorageItem('Activity Data', '25.3 MB'),
            _buildStorageItem('Photos', '12.8 MB'),
            _buildStorageItem('Cache', '8.5 MB'),
            _buildStorageItem('Settings', '0.2 MB'),
            const Divider(),
            _buildStorageItem('Total', '46.8 MB', isTotal: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// ストレージアイテム
  Widget _buildStorageItem(String label, String size, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            size,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 利用規約表示
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using FatGram, you agree to the following terms:\n\n'
            '1. Acceptance of Terms\n'
            'By accessing and using this app, you accept and agree to be bound by the terms and provision of this agreement.\n\n'
            '2. Use License\n'
            'Permission is granted to temporarily use FatGram for personal, non-commercial transitory viewing only.\n\n'
            '3. Disclaimer\n'
            'The materials on FatGram are provided on an "as is" basis. FatGram makes no warranties, expressed or implied.\n\n'
            '4. Limitations\n'
            'In no event shall FatGram be liable for any damages arising out of the use or inability to use the materials on this app.\n\n'
            'For complete terms, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// サポート連絡
  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening support email...'),
      ),
    );
    // TODO: メールアプリを開く処理
  }

  /// アプリ評価
  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening App Store...'),
      ),
    );
    // TODO: App Storeを開く処理
  }
}