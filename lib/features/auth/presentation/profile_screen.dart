import 'package:echo/app/router.dart';
import 'package:echo/features/auth/provider/auth_provider.dart';
import 'package:echo/features/auth/provider/profile_provider.dart';
import 'package:echo/shared/models/user_profile.dart';
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
    final source = await _showImageSourceSelector();
    if (source == null) return;

    final image = await ImagePicker().pickImage(source: source);
    if (image == null) return;

    if (!mounted) return;

    if (kIsWeb) {
      setState(() => _selectedImageUrl = image.path);
    } else {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<ImageSource?> _showImageSourceSelector() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => _ImageSourceBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).value;
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
    return Scaffold(
      backgroundColor: const Color(0xFF6E61FD),
      appBar: _ProfileAppBar(onBack: () => ref.read(routerProvider).go('/')),
      body: SafeArea(
        child: Column(
          children: [
            _ProfileHeader(
              user: user,
              selectedImage: _selectedImage,
              selectedImageUrl: _selectedImageUrl,
              onImagePressed: _pickImage,
            ),
            _ProfileForm(
              usernameController: _usernameController,
              aboutController: _aboutController,
              email: user?.email,
              onSave: () => _saveProfile(),
              onSignOut: _handleSignOut,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) {
      Fluttertoast.showToast(
        msg: 'Error: User profile not found.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    final updatedProfile = UserProfile(
      uid: profile.uid,
      email: profile.email,
      username: _usernameController.text,
      about: _aboutController.text,
      photoUrl: _selectedImageUrl ?? profile.photoUrl,
      level: profile.level,
      isNewUser: false,
    );

    await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
    Fluttertoast.showToast(
      msg: 'Profile updated successfully!',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

// Extracted Widgets for Better Organization

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

class _ProfileHeader extends StatelessWidget {
  final UserProfile? user;
  final File? selectedImage;
  final String? selectedImageUrl;
  final VoidCallback onImagePressed;

  const _ProfileHeader({
    required this.user,
    required this.selectedImage,
    required this.selectedImageUrl,
    required this.onImagePressed,
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
          ),
          const SizedBox(height: 20),
          const _LevelIndicator(),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final UserProfile? user;
  final File? selectedImage;
  final String? selectedImageUrl;
  final VoidCallback onPressed;

  const _ProfileAvatar({
    required this.user,
    required this.selectedImage,
    required this.selectedImageUrl,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(child: _getAvatarImage()),
          ),
        ),
        _EditImageButton(onPressed: onPressed),
      ],
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
        errorBuilder: (_, __, ___) => const _DefaultAvatar(),
      );
    }
    return const _DefaultAvatar();
  }
}

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

class _ProfileForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController aboutController;
  final String? email;
  final VoidCallback onSave;
  final VoidCallback onSignOut;

  const _ProfileForm({
    required this.usernameController,
    required this.aboutController,
    required this.email,
    required this.onSave,
    required this.onSignOut,
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
              ),
              const SizedBox(height: 40),
              _SaveButton(onPressed: onSave),
              const SizedBox(height: 24),
              _SignOutButton(onPressed: onSignOut),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E61FD),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
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

class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red, width: 1.5),
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

// Keep your existing _EditableField, _NonEditableField, and _DefaultAvatar classes
// Reusable Editable Field Component
class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int? maxLines;

  const _EditableField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
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
          ),
        ),
      ],
    );
  }
}

// Reusable Non-Editable Field Component
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
