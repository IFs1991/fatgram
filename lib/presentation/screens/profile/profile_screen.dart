import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../domain/models/user_model.dart';
import '../../../domain/models/activity_model.dart';
import '../../../domain/models/weekly_activity_stats.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/services/profile_image_service.dart';
import '../../../core/services/injector.dart';
import '../settings/settings_screen.dart';
import '../achievements/achievements_screen.dart';

/// プロフィール画面
///
/// ユーザー情報、統計データ、設定へのアクセスを
/// 美しいMaterial 3デザインで提供します。
class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final UserRepository _userRepository;
  late final ActivityRepository _activityRepository;
  late final ProfileImageService _profileImageService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  User? _user;
  WeeklyActivityStats? _weeklyStats;
  List<Activity> _recentActivities = [];

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;

  // 編集用コントローラー
  late TextEditingController _displayNameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeControllers();
    _loadProfileData();
  }

  void _initializeServices() {
    _userRepository = Injector().getUserRepository();
    _activityRepository = Injector().getActivityRepository(widget.userId);
    _profileImageService = ProfileImageService();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  void _initializeControllers() {
    _displayNameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// プロフィールデータを読み込み
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _loadUserData(),
        _loadWeeklyStats(),
        _loadRecentActivities(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// ユーザーデータを取得
  Future<void> _loadUserData() async {
    _user = await _userRepository.getCurrentUser();
    if (_user != null) {
      _updateControllers();
    }
  }

  /// 週間統計を取得
  Future<void> _loadWeeklyStats() async {
    final weekStart = _getStartOfWeek(DateTime.now());
    _weeklyStats = await _activityRepository.getWeeklyActivityStats(
      weekStartDate: weekStart,
    );
  }

  /// 最近のアクティビティを取得
  Future<void> _loadRecentActivities() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    _recentActivities = await _activityRepository.getActivities(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 週の開始日を取得
  DateTime _getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  /// コントローラーを更新
  void _updateControllers() {
    if (_user != null) {
      _displayNameController.text = _user!.displayName ?? '';
      _heightController.text = _user!.height?.toString() ?? '';
      _weightController.text = _user!.weight?.toString() ?? '';
      _ageController.text = _user!.age?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            _buildLoadingSliver()
          else if (_errorMessage != null)
            _buildErrorSliver()
          else
            _buildContentSliver(),
        ],
      ),
    );
  }

  /// アプリバーを構築
  Widget _buildAppBar() {
    return SliverAppBar.large(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_user?.displayName != null)
              Text(
                _user!.displayName!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: _buildProfileAvatar(size: 80),
          ),
        ),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _toggleEditMode,
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelEdit,
          ),
        ],
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _navigateToSettings(),
        ),
      ],
    );
  }

  /// プロフィールアバターを構築（画像アップロード機能付き）
  Widget _buildProfileAvatar({double size = 60}) {
    return GestureDetector(
      onTap: _isEditing ? _showImagePickerDialog : null,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: _isUploadingImage
                  ? _buildUploadingIndicator(size)
                  : _user?.photoUrl != null
                      ? Image.network(
                          _user!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(size),
                        )
                      : _buildDefaultAvatar(size),
            ),
          ),
          if (_isEditing && !_isUploadingImage)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: size * 0.15,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// アップロード中インジケーター
  Widget _buildUploadingIndicator(double size) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: _uploadProgress,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: size * 0.1,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// デフォルトアバターを構築
  Widget _buildDefaultAvatar(double size) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// ローディング表示
  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// エラー表示
  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadProfileData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// メインコンテンツ
  Widget _buildContentSliver() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ユーザー情報カード
              _buildUserInfoCard(),
              const SizedBox(height: 16),

              // 統計カード
              if (_weeklyStats != null) _buildStatsCard(),
              const SizedBox(height: 16),

              // アクション
              _buildActionsCard(),
              const SizedBox(height: 16),

              // 最近のアクティビティ
              _buildRecentActivityCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// ユーザー情報カード
  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 表示名
            _buildInfoField(
              icon: Icons.person,
              label: 'Name',
              value: _user?.displayName ?? 'Not set',
              controller: _displayNameController,
              isEditing: _isEditing,
            ),
            const SizedBox(height: 12),

            // メールアドレス
            _buildInfoField(
              icon: Icons.email,
              label: 'Email',
              value: _user?.email ?? 'Not set',
              isEditing: false, // メールは編集不可
            ),
            const SizedBox(height: 12),

            // 身長
            _buildInfoField(
              icon: Icons.height,
              label: 'Height',
              value: _user?.height != null ? '${_user!.height} cm' : 'Not set',
              controller: _heightController,
              isEditing: _isEditing,
              keyboardType: TextInputType.number,
              suffix: 'cm',
            ),
            const SizedBox(height: 12),

            // 体重
            _buildInfoField(
              icon: Icons.monitor_weight,
              label: 'Weight',
              value: _user?.weight != null ? '${_user!.weight} kg' : 'Not set',
              controller: _weightController,
              isEditing: _isEditing,
              keyboardType: TextInputType.number,
              suffix: 'kg',
            ),
            const SizedBox(height: 12),

            // 年齢
            _buildInfoField(
              icon: Icons.cake,
              label: 'Age',
              value: _user?.age != null ? '${_user!.age} years' : 'Not set',
              controller: _ageController,
              isEditing: _isEditing,
              keyboardType: TextInputType.number,
              suffix: 'years',
            ),

            // プレミアムステータス
            if (_user?.isPremium == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Premium Member',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 情報フィールドを構築
  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditing = false,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              if (isEditing && controller != null)
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: const UnderlineInputBorder(),
                    suffixText: suffix,
                  ),
                )
              else
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 統計カード
  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week\'s Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_fire_department,
                    label: 'Fat Burned',
                    value: '${_weeklyStats!.totalFatGramsBurned.toStringAsFixed(1)}g',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.flash_on,
                    label: 'Calories',
                    value: '${_weeklyStats!.totalCaloriesBurned.toStringAsFixed(0)}',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: _formatDuration(_weeklyStats!.totalDurationInSeconds),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.fitness_center,
                    label: 'Activities',
                    value: '${_weeklyStats!.totalActivityCount}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 統計アイテム
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// アクションカード
  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.emoji_events,
              title: 'Achievements',
              subtitle: 'View your badges and milestones',
              onTap: _navigateToAchievements,
            ),
            const Divider(height: 24),
            _buildActionItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Customize your app experience',
              onTap: _navigateToSettings,
            ),
            const Divider(height: 24),
            _buildActionItem(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Log out of your account',
              onTap: _showSignOutDialog,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  /// アクションアイテム
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? color : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      onTap: onTap,
    );
  }

  /// 最近のアクティビティカード
  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // ダッシュボードに戻る
                    Navigator.of(context).pop();
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activities',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.take(3).length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _getActivityColor(activity.type).withOpacity(0.1),
                      child: Icon(
                        _getActivityIcon(activity.type),
                        color: _getActivityColor(activity.type),
                      ),
                    ),
                    title: Text(
                      _getActivityName(activity.type),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _formatTimeAgo(activity.timestamp),
                    ),
                    trailing: Text(
                      '${activity.caloriesBurned.toStringAsFixed(0)} cal',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 編集モード切り替え
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  /// プロフィール保存
  void _saveProfile() async {
    if (_user == null) return;

    try {
      final updatedUser = _user!.copyWith(
        displayName: _displayNameController.text.isNotEmpty
            ? _displayNameController.text
            : null,
        height: _heightController.text.isNotEmpty
            ? int.tryParse(_heightController.text)
            : null,
        weight: _weightController.text.isNotEmpty
            ? int.tryParse(_weightController.text)
            : null,
        age: _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
      );

      final savedUser = await _userRepository.updateUser(updatedUser);

      setState(() {
        _user = savedUser;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 編集キャンセル
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _updateControllers(); // 元の値に戻す
  }

  /// 設定画面に移動
  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(userId: widget.userId),
      ),
    );
  }

  /// アチーブメント画面に移動
  void _navigateToAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AchievementsScreen(userId: widget.userId),
      ),
    );
  }

  /// 画像選択ダイアログ
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'プロフィール画像を選択',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_user?.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('現在の画像を削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfileImage();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  /// 画像選択
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploadingImage = true;
        _uploadProgress = 0.0;
      });
      
      final imageFile = await _profileImageService.selectImage(source: source);
      
      if (imageFile != null) {
        // 画像アップロード
        final imageUrls = await _profileImageService.uploadProfileImage(
          userId: widget.userId,
          imageFile: imageFile,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
        
        // ユーザープロフィール更新
        if (_user != null) {
          final updatedUser = _user!.copyWith(
            photoUrl: imageUrls['profile'],
            thumbnailUrl: imageUrls['thumbnail'],
            updatedAt: DateTime.now(),
          );
          
          await _userRepository.updateUser(updatedUser);
          
          setState(() {
            _user = updatedUser;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('プロフィール画像が更新されました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像のアップロードに失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 0.0;
      });
    }
  }
  
  /// プロフィール画像削除
  Future<void> _deleteProfileImage() async {
    try {
      if (_user?.photoUrl != null) {
        // Firebase Storageから画像削除
        final imageUrls = [_user!.photoUrl!];
        if (_user!.thumbnailUrl != null) {
          imageUrls.add(_user!.thumbnailUrl!);
        }
        
        await _profileImageService.deleteProfileImages(
          userId: widget.userId,
          imageUrls: imageUrls,
        );
        
        // ユーザープロフィール更新
        final updatedUser = _user!.copyWith(
          photoUrl: null,
          thumbnailUrl: null,
          updatedAt: DateTime.now(),
        );
        
        await _userRepository.updateUser(updatedUser);
        
        setState(() {
          _user = updatedUser;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィール画像が削除されました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の削除に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// サインアウトダイアログ
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _userRepository.logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to sign out: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// アクティビティアイコンを取得
  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.workout:
        return Icons.fitness_center;
      default:
        return Icons.fitness_center;
    }
  }

  /// アクティビティ色を取得
  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Colors.orange;
      case ActivityType.cycling:
        return Colors.blue;
      case ActivityType.swimming:
        return Colors.cyan;
      case ActivityType.walking:
        return Colors.green;
      case ActivityType.workout:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// アクティビティ名を取得
  String _getActivityName(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.swimming:
        return 'Swimming';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.workout:
        return 'Workout';
      default:
        return 'Activity';
    }
  }

  /// 継続時間をフォーマット
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// 時間差をフォーマット
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}