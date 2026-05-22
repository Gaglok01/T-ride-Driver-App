import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:t_rider_services_app/config/api_urls.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/data/local/secure_storage_service.dart';
import 'package:t_rider_services_app/data/models/user_profile_model.dart';
import 'package:t_rider_services_app/data/repositories/profile_repository.dart';
import 'package:t_rider_services_app/views/widgets/app_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final SecureStorageService _secureStorage = SecureStorageService();

  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  File? _selectedPhoto;

  String _carModel = '';
  String _carPlate = '';
  String _carColor = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadProfile(), _loadCarInfo()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) AppSnackbar.showApiError(e, fallbackMessage: 'Unable to load profile.');
    }
  }

  Future<void> _loadCarInfo() async {
    final info = await _secureStorage.getCarInfo();
    if (!mounted) return;
    setState(() {
      _carModel = info['model'] ?? '';
      _carPlate = info['plateNumber'] ?? '';
      _carColor = info['color'] ?? '';
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82);
      if (picked == null) return;
      setState(() => _selectedPhoto = File(picked.path));
      await _openEditSheet();
    } catch (_) {
      AppSnackbar.showError(message: 'Unable to select photo.');
    }
  }

  Future<void> _openEditSheet() async {
    final p = _profile;
    final name = TextEditingController(text: p?.name ?? '');
    final address = TextEditingController(text: p?.address ?? '');
    final city = TextEditingController(text: p?.city ?? '');
    final region = TextEditingController(text: p?.city ?? '');
    final carModel = TextEditingController(text: _carModel);
    final plate = TextEditingController(text: _carPlate);
    final color = TextEditingController(text: _carColor);

    Future<void> save() async {
      if (_saving) return;
      setState(() => _saving = true);
      try {
        final updated = await _profileRepository.updateProfile(
          name: name.text.trim().isEmpty ? 'T-Ride Driver' : name.text.trim(),
          address: address.text.trim(),
          region: region.text.trim(),
          city: city.text.trim(),
          role: 'driver',
          photoFile: _selectedPhoto,
        );
        await _secureStorage.saveCarInfo(
          model: carModel.text.trim(),
          plateNumber: plate.text.trim(),
          color: color.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _profile = updated;
          _carModel = carModel.text.trim();
          _carPlate = plate.text.trim();
          _carColor = color.text.trim();
          _selectedPhoto = null;
        });
        Navigator.pop(context);
        AppSnackbar.showSuccess(message: 'Profile updated.');
      } catch (e) {
        AppSnackbar.showApiError(e, fallbackMessage: 'Unable to update profile.');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28.r))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 22.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44.w, height: 5.h, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999.r))),
              SizedBox(height: 16.h),
              Text('Edit profile', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 4.h),
              Text('Keep your driver account accurate and ready for verification.', style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              SizedBox(height: 16.h),
              _input(name, 'Full name'),
              _input(address, 'Address'),
              Row(children: [Expanded(child: _input(city, 'City')), SizedBox(width: 10.w), Expanded(child: _input(region, 'Region'))]),
              Divider(height: 28.h),
              _input(carModel, 'Vehicle model'),
              Row(children: [Expanded(child: _input(plate, 'Plate number')), SizedBox(width: 10.w), Expanded(child: _input(color, 'Color'))]),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppConst.primaryColor, foregroundColor: Colors.black, padding: EdgeInsets.symmetric(vertical: 15.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
                  child: Text(_saving ? 'Saving...' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  String? get _photoUrl {
    final raw = _profile?.photo?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiUrls.baseUrl}$raw';
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: EdgeInsets.all(18.w),
                  children: [
                    _pageHeader(),
                    SizedBox(height: 14.h),
                    _profileHero(p),
                    SizedBox(height: 14.h),
                    _stats(),
                    SizedBox(height: 14.h),
                    _statusCard(),
                    SizedBox(height: 14.h),
                    _vehicleCard(),
                    SizedBox(height: 14.h),
                    _documentsCard(),
                    SizedBox(height: 14.h),
                    _preferencesCard(),
                    SizedBox(height: 14.h),
                    _accountCard(),
                    SizedBox(height: 22.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _pageHeader() {
    return Row(
      children: [
        IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded, color: AppConst.primaryColor), style: IconButton.styleFrom(backgroundColor: Colors.white)),
        SizedBox(width: 10.w),
        Expanded(child: Text('Driver profile', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900))),
        IconButton(onPressed: _openEditSheet, icon: const Icon(Icons.edit_rounded), style: IconButton.styleFrom(backgroundColor: AppConst.primaryColor, foregroundColor: Colors.black)),
      ],
    );
  }

  Widget _profileHero(UserProfile? p) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _decoration(),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: AppConst.primaryColor.withOpacity(0.25),
                  backgroundImage: _selectedPhoto != null ? FileImage(_selectedPhoto!) : (_photoUrl == null ? null : NetworkImage(_photoUrl!) as ImageProvider),
                  child: _selectedPhoto == null && _photoUrl == null ? Icon(Icons.person_rounded, size: 38.sp, color: AppConst.primaryColor) : null,
                ),
                Positioned(right: 0, bottom: 0, child: Container(padding: EdgeInsets.all(6.w), decoration: const BoxDecoration(color: AppConst.primaryColor, shape: BoxShape.circle), child: Icon(Icons.camera_alt_rounded, size: 14.sp, color: Colors.black))),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(p?.name?.trim().isEmpty == false ? p!.name! : 'T-Ride Driver', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 21.sp, fontWeight: FontWeight.w900))), Icon(Icons.verified_rounded, color: Colors.green, size: 20.sp)]),
                SizedBox(height: 4.h),
                Text(p?.email ?? p?.phoneNumber ?? 'Driver account', style: TextStyle(fontSize: 12.sp, color: Colors.black54, fontWeight: FontWeight.w600)),
                SizedBox(height: 10.h),
                Wrap(spacing: 8.w, runSpacing: 6.h, children: [_pill('Verified'), _pill('Silver tier'), _pill('Active')]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Row(
      children: [
        Expanded(child: _statBox('Rating', 'New')),
        SizedBox(width: 10.w),
        Expanded(child: _statBox('Trips', '0')),
        SizedBox(width: 10.w),
        Expanded(child: _statBox('Wallet', _profile?.walletBalance == null ? '\$0.00' : '\$${_profile!.walletBalance}')),
      ],
    );
  }

  Widget _statusCard() {
    return _sectionCard(
      title: 'Account status',
      icon: Icons.workspace_premium_rounded,
      children: [
        _progressRow('Verification', 'Ready', 0.75),
        SizedBox(height: 10.h),
        _progressRow('Profile strength', 'Good', 0.68),
        SizedBox(height: 10.h),
        _progressRow('Next tier', 'Complete 3 more trips', 0.35),
      ],
    );
  }

  Widget _vehicleCard() {
    final hasVehicle = _carModel.isNotEmpty || _carPlate.isNotEmpty || _carColor.isNotEmpty;
    return _sectionCard(
      title: 'Vehicle',
      icon: Icons.directions_car_filled_rounded,
      action: TextButton(onPressed: _openEditSheet, child: const Text('Edit')),
      children: hasVehicle
          ? [_infoRow('Model', _carModel.isEmpty ? 'Not set' : _carModel), _infoRow('Plate', _carPlate.isEmpty ? 'Not set' : _carPlate), _infoRow('Color', _carColor.isEmpty ? 'Not set' : _carColor), _infoRow('Type', 'Economy')]
          : [Text('Add vehicle details before accepting live trips.', style: TextStyle(fontSize: 13.sp, color: Colors.black54, height: 1.35))],
    );
  }

  Widget _documentsCard() {
    return _sectionCard(
      title: 'Documents',
      icon: Icons.shield_rounded,
      children: [
        _document('Driver license', 'Verification pending', Icons.badge_rounded, Colors.orange),
        _document('Insurance', 'Upload required', Icons.description_rounded, Colors.red),
        _document('Vehicle registration', 'Upload required', Icons.article_rounded, Colors.red),
        _document('Background check', 'Not submitted', Icons.verified_user_rounded, Colors.orange),
      ],
    );
  }

  Widget _preferencesCard() {
    return _sectionCard(
      title: 'Work preferences',
      icon: Icons.tune_rounded,
      children: [
        _infoRow('Ride requests', 'Enabled'),
        _infoRow('Bid rides', 'Available'),
        _infoRow('Pooling', 'Available'),
        _infoRow('Courier', 'Available'),
      ],
    );
  }

  Widget _accountCard() {
    return _sectionCard(
      title: 'Account',
      icon: Icons.manage_accounts_rounded,
      children: [
        _menu('Personal information', Icons.person_outline_rounded, _openEditSheet),
        _menu('Earnings & payout', Icons.account_balance_wallet_outlined, () => AppSnackbar.showSuccess(title: 'Earnings', message: 'Ready for backend connection.')),
        _menu('Security', Icons.lock_outline_rounded, () => AppSnackbar.showSuccess(title: 'Security', message: 'Ready for backend connection.')),
        _menu('Help & support', Icons.support_agent_rounded, () => AppSnackbar.showSuccess(title: 'Support', message: 'Ready for backend connection.')),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, Widget? action, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _decoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: AppConst.primaryColor, size: 22.sp), SizedBox(width: 10.w), Expanded(child: Text(title, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900))), if (action != null) action]),
        SizedBox(height: 12.h),
        ...children,
      ]),
    );
  }

  Widget _progressRow(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text(value, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700))]),
        SizedBox(height: 7.h),
        ClipRRect(borderRadius: BorderRadius.circular(999.r), child: LinearProgressIndicator(value: progress, minHeight: 7.h, backgroundColor: Colors.black.withOpacity(0.06), valueColor: AlwaysStoppedAnimation<Color>(AppConst.primaryColor))),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(children: [Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.black54, fontWeight: FontWeight.w700)), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)))]),
    );
  }

  Widget _document(String title, String subtitle, IconData icon, Color statusColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(16.r)),
      child: Row(children: [Icon(icon, size: 22.sp, color: AppConst.primaryColor), SizedBox(width: 10.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 2.h), Text(subtitle, style: TextStyle(fontSize: 11.sp, color: Colors.black45))])), Icon(Icons.circle, color: statusColor, size: 10.sp)]),
    );
  }

  Widget _menu(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppConst.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppConst.primaryColor.withOpacity(0.75)),
      onTap: onTap,
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: _decoration(),
      child: Column(children: [Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)), SizedBox(height: 4.h), Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.black54, fontWeight: FontWeight.w700))]),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(color: AppConst.primaryColor.withOpacity(0.22), borderRadius: BorderRadius.circular(999.r)),
      child: Text(text, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900)),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8))],
    );
  }
}
