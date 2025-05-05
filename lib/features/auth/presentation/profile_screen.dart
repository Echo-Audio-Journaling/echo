import 'package:echo/app/router.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/auth/provider/profile_provider.dart';
import 'package:echo/shared/models/user_profile.dart';
import 'package:echo/shared/utils/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _aboutController;
  File? _selectedImage;
  String? _selectedImageUrl;
  bool _isSaving = false; // Track overall saving state
  bool _isImageUploading = false; // Track specific image upload state
  String _loadingMessage = 'Loading...'; // Dynamic loading message

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _aboutController = TextEditingController();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = ref.read(userProfileProvider).value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        _usernameController.text = user.username;
        _aboutController.text = user.about ?? 'About yourself...';
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await _showSignOutConfirmation();
    if (shouldSignOut == true) {
      await ref.read(authStateProvider.notifier).signOut();
      ref.read(routerProvider).go('/signin');
    }
  }

  Future<bool?> _showSignOutConfirmation() async {
    return showDialog<bool>(
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
  }

  Future<void> _pickImage() async {
    // Don't allow picking a new image while one is being uploaded
    if (_isImageUploading) return;

    final source = await _showImageSourceSelector();
    if (source == null) return;

    try {
      setState(() => _isImageUploading = true);

      final image = await ImagePicker().pickImage(
        source: source,
        // Optimize by compressing the image before upload
        maxHeight: 1200,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isImageUploading = false);
        return;
      }

      if (!mounted) return;

      if (kIsWeb) {
        setState(() {
          _selectedImageUrl = image.path;
          _isImageUploading = false;
        });
      } else {
        setState(() {
          _selectedImage = File(image.path);
          _isImageUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImageUploading = false);
        _showErrorToast('Failed to select image: ${e.toString()}');
      }
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  Future<ImageSource?> _showImageSourceSelector() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => _ImageSourceBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the userProfileProvider to react to its state changes
    final userProfileState = ref.watch(userProfileProvider);

    // Listen for changes to update controllers when data is loaded
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (_, next) {
      next.when(
        data: (user) {
          if (user != null) {
            _usernameController.text = user.username;
            _aboutController.text = user.about ?? 'About yourself...';
          }
        },
        error: (e, _) => debugPrint('Error fetching user profile: $e'),
        loading: () => debugPrint('Loading user profile...'),
      );
    });

    // Return a Scaffold with either loading indicator or profile content
    return Scaffold(
      backgroundColor: const Color(0xFF6E61FD),
      appBar: _ProfileAppBar(onBack: () => ref.read(routerProvider).go('/')),
      // Show saving overlay if saving
      body: Stack(
        children: [
          SafeArea(
            child: userProfileState.when(
              // Show loading indicator while data is loading
              loading:
                  () => const _LoadingProfile(message: 'Loading profile...'),

              // Show error state if there's an error
              error:
                  (error, stackTrace) => _ErrorProfile(
                    error: error.toString(),
                    onRetry: () => ref.refresh(userProfileProvider),
                  ),

              // Show profile content when data is loaded
              data: (user) {
                if (user == null) {
                  // Handle case where user is null (not logged in or data not found)
                  return const _ErrorProfile(
                    error: 'User profile not found',
                    onRetry: null,
                  );
                }

                return Column(
                  children: [
                    _ProfileHeader(
                      user: user,
                      selectedImage: _selectedImage,
                      selectedImageUrl: _selectedImageUrl,
                      onImagePressed: _pickImage,
                      isImageUploading: _isImageUploading,
                    ),
                    _ProfileForm(
                      usernameController: _usernameController,
                      aboutController: _aboutController,
                      email: user.email,
                      onSave: () => _saveProfile(),
                      onSignOut: _handleSignOut,
                      isSaving: _isSaving,
                    ),
                  ],
                );
              },
            ),
          ),
          // Show saving overlay if necessary
          if (_isSaving) _SavingOverlay(message: _loadingMessage),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return; // Prevent multiple save operations

    setState(() {
      _isSaving = true;
      _loadingMessage = 'Saving profile...';
    });

    final profile = ref.read(userProfileProvider).value;
    if (profile == null) {
      setState(() => _isSaving = false);
      _showErrorToast('Error: User profile not found.');
      return;
    }

    try {
      // Upload image if there is one
      String? imageUrl;
      final StorageService storageService = StorageService();
      setState(() => _loadingMessage = 'Updating profile data...');

      if (_selectedImage != null || _selectedImageUrl != null) {
        // setState(() => _loadingMessage = 'Processing image...');

        // First delete the old image if it exists
        if (profile.photoUrl != null) {
          // setState(() => _loadingMessage = 'Removing old image...');
          try {
            final oldImagePath = await storageService.getReferencePathFromUrl(
              profile.photoUrl!,
            );
            if (oldImagePath != null) {
              await storageService.deleteFile(oldImagePath);
            }
          } catch (e) {
            // If error deleting old image, continue with upload anyway
            debugPrint('Error deleting old image: $e');
          }
        }

        // Upload the new image with optimized approach
        // setState(() => _loadingMessage = 'Uploading new image...');
        if (_selectedImage != null) {
          // Optimize by uploading in a try-catch block with timeout
          try {
            imageUrl = await _uploadImageWithTimeout(
              storageService,
              XFile(_selectedImage!.path),
              profile.uid,
            );
          } catch (e) {
            _showErrorToast('Image upload timed out. Try again later.');
            setState(() => _isSaving = false);
            return;
          }
        } else if (_selectedImageUrl != null) {
          // Handle web platforms
          imageUrl = _selectedImageUrl;
        }
      }

      // Update profile in Firestore
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

      // Success state
      if (mounted) {
        setState(() => _isSaving = false);
        Fluttertoast.showToast(
          msg: 'Profile updated successfully!',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorToast('Failed to update profile: ${e.toString()}');
      }
    }
  }

  // Helper method to upload image with timeout
  Future<String?> _uploadImageWithTimeout(
    StorageService storageService,
    XFile file,
    String uid, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await storageService.uploadXFile(file, uid).timeout(timeout);
    } catch (e) {
      debugPrint('Image upload error: $e');
      rethrow;
    }
  }
}

// Loading state widget with customizable message
class _LoadingProfile extends StatelessWidget {
  final String message;

  const _LoadingProfile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular loading indicator with custom color
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          // Loading text
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
}

// Saving overlay that shows the current operation
class _SavingOverlay extends StatelessWidget {
  final String message;

  const _SavingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
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
                  message,
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

// Error state widget
class _ErrorProfile extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _ErrorProfile({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            // Error message
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Error details
            Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Retry button (if available)
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
}

// Modified ProfileHeader to show loading state on avatar
class _ProfileHeader extends StatelessWidget {
  final UserProfile? user;
  final File? selectedImage;
  final String? selectedImageUrl;
  final VoidCallback onImagePressed;
  final bool isImageUploading;

  const _ProfileHeader({
    required this.user,
    required this.selectedImage,
    required this.selectedImageUrl,
    required this.onImagePressed,
    required this.isImageUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(color: Color(0xFF6E61FD)),
      child: Column(
        children: [
          _ProfileAvatar(
            user: user,
            selectedImage: selectedImage,
            selectedImageUrl: selectedImageUrl,
            onPressed: onImagePressed,
            isLoading: isImageUploading,
          ),
          const SizedBox(height: 20),
          const _LevelIndicator(),
        ],
      ),
    );
  }
}

// Modified ProfileAvatar to show loading state
class _ProfileAvatar extends StatelessWidget {
  final UserProfile? user;
  final File? selectedImage;
  final String? selectedImageUrl;
  final VoidCallback onPressed;
  final bool isLoading;

  const _ProfileAvatar({
    required this.user,
    required this.selectedImage,
    required this.selectedImageUrl,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: isLoading ? null : onPressed, // Disable when loading
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: isLoading ? _buildLoadingAvatar() : _getAvatarImage(),
            ),
          ),
        ),
        if (!isLoading) _EditImageButton(onPressed: onPressed),
      ],
    );
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

  Widget _getAvatarImage() {
    if (selectedImage != null) {
      return Image.file(selectedImage!, fit: BoxFit.cover);
    }
    if (selectedImageUrl != null) {
      return Image.network(selectedImageUrl!, fit: BoxFit.cover);
    }
    if (user?.photoUrl != null) {
      return Image.network(
        user!.photoUrl!,
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
        errorBuilder: (_, __, ___) => const _DefaultAvatar(),
      );
    }
    return const _DefaultAvatar();
  }
}

// Modified ProfileForm with disabled save button when saving
class _ProfileForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController aboutController;
  final String? email;
  final VoidCallback onSave;
  final VoidCallback onSignOut;
  final bool isSaving;

  const _ProfileForm({
    required this.usernameController,
    required this.aboutController,
    required this.email,
    required this.onSave,
    required this.onSignOut,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
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
              _EditableField(
                label: 'Username',
                controller: usernameController,
                icon: Icons.person_outline,
                enabled: !isSaving,
              ),
              const SizedBox(height: 24),
              _NonEditableField(
                label: 'Email',
                value: email ?? 'no-email@example.com',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              _EditableField(
                label: 'About',
                controller: aboutController,
                icon: Icons.info_outline,
                maxLines: 4,
                enabled: !isSaving,
              ),
              const SizedBox(height: 40),
              _SaveButton(
                onPressed: isSaving ? null : onSave,
                isLoading: isSaving,
              ),
              const SizedBox(height: 24),
              _SignOutButton(
                onPressed: isSaving ? () {} : onSignOut,
                enabled: !isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modified SaveButton to show loading state
class _SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SaveButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E61FD),
            disabledBackgroundColor: const Color(0xFF6E61FD).withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              isLoading
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
}

// Modified SignOutButton to handle disabled state
class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _SignOutButton({required this.onPressed, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            disabledForegroundColor: Colors.red.withOpacity(0.5),
            side: BorderSide(
              color: enabled ? Colors.red : Colors.red.withOpacity(0.5),
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
}

// Modified EditableField to handle disabled state
class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int? maxLines;
  final bool enabled;

  const _EditableField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
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
          enabled: enabled,
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
}

// Keep other widgets as-is
class _EditImageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditImageButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.edit, color: Color(0xFF6E61FD), size: 20),
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  const _LevelIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8D84FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Level 3 Explorer',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _NonEditableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _NonEditableField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF6E61FD)),
              const SizedBox(width: 12),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/profile/default_profile.png', fit: BoxFit.cover);
  }
}

class _ImageSourceBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose image source',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF6E61FD)),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF6E61FD)),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const _ProfileAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF6E61FD),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack,
      ),
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
