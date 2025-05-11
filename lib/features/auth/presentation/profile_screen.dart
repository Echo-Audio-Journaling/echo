import 'package:echo/app/router.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/auth/provider/profile_provider.dart';
import 'package:echo/features/media_upload/services/storage_service.dart';
import 'package:echo/shared/models/user_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Controllers
  late final TextEditingController _usernameController;
  late final TextEditingController _aboutController;

  // Image state
  File? _selectedImage;
  String? _selectedImageUrl;

  // Loading states
  bool _isSaving = false;
  bool _isImageUploading = false;
  String _loadingMessage = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _usernameController = TextEditingController();
    _aboutController = TextEditingController();

    // Initialize with user data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateUserData();
    });
  }

  void _populateUserData() {
    final user = ref.read(userProfileProvider).value;
    if (user != null) {
      _usernameController.text = user.username;
      _aboutController.text = user.about ?? 'About yourself...';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  // Image selection
  Future<void> _pickImage() async {
    if (_isImageUploading) return;

    final source = await _showImageSourceOptions();
    if (source == null) return;

    setState(() => _isImageUploading = true);

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxHeight: 1200,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (image == null || !mounted) {
        setState(() => _isImageUploading = false);
        return;
      }

      setState(() {
        if (kIsWeb) {
          _selectedImageUrl = image.path;
        } else {
          _selectedImage = File(image.path);
        }
        _isImageUploading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isImageUploading = false);
        _showToast('Failed to select image: $e', isError: true);
      }
    }
  }

  Future<ImageSource?> _showImageSourceOptions() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF6E61FD),
                  ),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF6E61FD),
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
  }

  // Save profile changes
  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _loadingMessage = 'Saving profile...';
    });

    final profile = ref.read(userProfileProvider).value;
    if (profile == null) {
      setState(() => _isSaving = false);
      _showToast('Error: User profile not found.', isError: true);
      return;
    }

    try {
      // Handle image upload
      String? imageUrl;

      if (_selectedImage != null || _selectedImageUrl != null) {
        // Delete old image if it exists
        if (profile.photoUrl != null) {
          try {
            final oldImagePath = await ref
                .read(storageServiceProvider)
                .getReferencePathFromUrl(profile.photoUrl!);
            if (oldImagePath != null) {
              await ref.read(storageServiceProvider).deleteFile(oldImagePath);
            }
          } catch (e) {
            debugPrint('Error deleting old image: $e');
          }
        }

        // Upload new image
        if (_selectedImage != null) {
          try {
            imageUrl = await _uploadImageWithTimeout(
              XFile(_selectedImage!.path),
              profile.uid,
            );
          } catch (e) {
            _showToast('Image upload timed out', isError: true);
            setState(() => _isSaving = false);
            return;
          }
        } else if (_selectedImageUrl != null) {
          imageUrl = _selectedImageUrl;
        }
      }

      // Update profile data
      final updatedProfile = UserProfile(
        uid: profile.uid,
        email: profile.email,
        username: _usernameController.text,
        about: _aboutController.text,
        photoUrl: imageUrl ?? profile.photoUrl,
        level: profile.level,
        isNewUser: false,
      );

      await ref
          .read(userProfileProvider.notifier)
          .updateProfile(updatedProfile);

      if (mounted) {
        setState(() => _isSaving = false);
        _showToast('Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast('Failed to update profile: $e', isError: true);
      }
    }
  }

  Future<String?> _uploadImageWithTimeout(XFile file, String uid) {
    return ref
        .read(storageServiceProvider)
        .uploadProfile(file, uid)
        .timeout(const Duration(seconds: 30));
  }

  // Sign out
  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldSignOut == true) {
      await ref.read(authStateProvider.notifier).signOut();
      ref.read(routerProvider).go('/signin');
    }
  }

  // Helper to display toast notifications
  void _showToast(String message, {bool isError = false}) {
    final successSnackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    ScaffoldMessenger.of(context).showSnackBar(successSnackBar);
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);

    // Update controllers when user data changes
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (_, next) {
      next.whenData((user) {
        if (user != null) {
          _usernameController.text = user.username;
          _aboutController.text = user.about ?? 'About yourself...';
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF6E61FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E61FD),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => ref.read(routerProvider).go('/'),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: userProfileState.when(
              loading: () => _buildLoadingView('Loading profile...'),
              error:
                  (error, _) => _buildErrorView(
                    error.toString(),
                    () => ref.refresh(userProfileProvider),
                  ),
              data:
                  (user) =>
                      user == null
                          ? _buildErrorView('User profile not found', null)
                          : _buildProfileView(user),
            ),
          ),
          if (_isSaving) _buildSavingOverlay(),
        ],
      ),
    );
  }

  // UI Components
  Widget _buildProfileView(UserProfile user) {
    return Column(
      children: [_buildProfileHeader(user), _buildProfileForm(user)],
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(color: Color(0xFF6E61FD)),
      child: Column(
        children: [
          _buildProfileAvatar(user),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8D84FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Level 3 Explorer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile user) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: _isImageUploading ? null : _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child:
                  _isImageUploading
                      ? _buildLoadingAvatar()
                      : _buildAvatarImage(user),
            ),
          ),
        ),
        if (!_isImageUploading)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Color(0xFF6E61FD), size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarImage(UserProfile user) {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }
    if (_selectedImageUrl != null) {
      return Image.network(_selectedImageUrl!, fit: BoxFit.cover);
    }
    if (user.photoUrl != null) {
      return Image.network(
        user.photoUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
        errorBuilder:
            (_, __, ___) => Image.asset(
              'assets/profile/default_profile.png',
              fit: BoxFit.cover,
            ),
      );
    }
    return Image.asset('assets/profile/default_profile.png', fit: BoxFit.cover);
  }

  Widget _buildLoadingAvatar() {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildProfileForm(UserProfile user) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditableField(
                'Username',
                _usernameController,
                Icons.person_outline,
              ),
              const SizedBox(height: 24),
              _buildNonEditableField('Email', user.email, Icons.email_outlined),
              const SizedBox(height: 24),
              _buildEditableField(
                'About',
                _aboutController,
                Icons.info_outline,
                maxLines: 4,
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 24),
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF281CA3),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: !_isSaving,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6E61FD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC6C2FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC6C2FF)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFC6C2FF).withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNonEditableField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF281CA3),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC6C2FF)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6E61FD)),
              const SizedBox(width: 12),
              Expanded(child: Text(value)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E61FD),
            disabledBackgroundColor: const Color(0xFF6E61FD).withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isSaving
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Center(
      child: SizedBox(
        width: 200,
        child: OutlinedButton(
          onPressed: _isSaving ? null : _signOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            disabledForegroundColor: Colors.red.withOpacity(0.5),
            side: BorderSide(
              color: _isSaving ? Colors.red.withOpacity(0.5) : Colors.red,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, VoidCallback? onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6E61FD),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E61FD)),
                ),
                const SizedBox(height: 24),
                Text(
                  _loadingMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
