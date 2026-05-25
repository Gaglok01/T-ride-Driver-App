import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:t_rider_services_app/config/api_urls.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/data/local/secure_storage_service.dart';
import 'package:t_rider_services_app/data/models/user_profile_model.dart';
import 'package:t_rider_services_app/data/models/driver_dashboard_model.dart';
import 'package:t_rider_services_app/data/repositories/rider_status_repository.dart';
import 'package:t_rider_services_app/data/repositories/driver_dashboard_repository.dart';
import 'package:t_rider_services_app/data/repositories/profile_repository.dart';
import 'package:t_rider_services_app/data/repositories/driver_onboarding_repository.dart';
import 'package:t_rider_services_app/views/widgets/app_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final DriverDashboardRepository _dashboardRepository = DriverDashboardRepository();
  DriverDashboardData? _dashboard;

  final DriverOnboardingRepository _driverOnboardingRepository =
      DriverOnboardingRepository();
  final SecureStorageService _secureStorage = SecureStorageService();

  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  File? _selectedPhoto;
  File? _licenseFront;
  File? _licenseBack;
  File? _insurance;
  File? _vehicleRegistration;
  File? _vehiclePhoto;

  bool _uploadingDocs = false;
  String _accountStatus = 'pending';
  Map<String, String> _documentStatuses = {};

  String _carModel = '';
  String _carPlate = '';
  String _carColor = '';
  bool _rideRequestsEnabled = true;
  bool _bidEnabled = true;
  bool _poolingEnabled = true;
  bool _courierEnabled = true;
  bool _deliveryEnabled = true;
  bool _petFriendlyEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadProfile(), _loadCarInfo(), _loadDashboard()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDashboard() async {
    try {
      final dashMap = await _dashboardRepository.getDashboard();
      final dash = DriverDashboardData.fromJson(dashMap['data'] ?? dashMap);
      if (mounted) setState(() => _dashboard = dash);
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted)
        AppSnackbar.showApiError(e, fallbackMessage: 'Unable to load profile.');
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
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 1200,
        maxHeight: 1200,
      );
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
        AppSnackbar.showApiError(
          e,
          fallbackMessage: 'Unable to update profile.',
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          18.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 22.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Edit profile',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4.h),
              Text(
                'Keep your driver account accurate and ready for verification.',
                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
              ),
              SizedBox(height: 16.h),
              _input(name, 'Full name'),
              _input(address, 'Address'),
              Row(
                children: [
                  Expanded(child: _input(city, 'City')),
                  SizedBox(width: 10.w),
                  Expanded(child: _input(region, 'Region')),
                ],
              ),
              Divider(height: 28.h),
              _input(carModel, 'Vehicle model'),
              Row(
                children: [
                  Expanded(child: _input(plate, 'Plate number')),
                  SizedBox(width: 10.w),
                  Expanded(child: _input(color, 'Color')),
                ],
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConst.primaryColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  String? get _photoUrl {
    final raw = (_dashboard?.profileImage ?? _profile?.photo)?.trim();
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
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppConst.primaryColor,
          ),
          style: IconButton.styleFrom(backgroundColor: Colors.white),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            'Driver profile',
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          onPressed: _openEditSheet,
          icon: const Icon(Icons.edit_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppConst.primaryColor,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _profileHero(UserProfile? p) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _decoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 42.r,
                      backgroundColor: AppConst.primaryColor.withOpacity(0.15),
                      backgroundImage: _selectedPhoto != null
                          ? FileImage(_selectedPhoto!)
                          : (_photoUrl == null
                                ? null
                                : NetworkImage(_photoUrl!) as ImageProvider),
                      child: _selectedPhoto == null && _photoUrl == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 40.sp,
                              color: AppConst.primaryColor,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                          color: AppConst.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 14.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p?.name ?? 'Driver',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.green,
                          size: 22.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      p?.email ?? '',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      p?.phoneNumber ?? '',
                      style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _badge(_dashboard?.verified == true ? 'Verified' : 'Unverified', Colors.green.shade100),
                        _badge(_dashboard?.tier ?? 'Standard', const Color(0xFFF3F3F3)),
                        _badge(
                          (_dashboard?.accountStatus ?? _accountStatus).toUpperCase(),
                          AppConst.primaryColor.withOpacity(0.22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _premiumStat(
                  _dashboard?.rating?.toString() ?? '0',
                  'Rating',
                  Icons.star_rounded,
                  '128 reviews',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _premiumStat(
                  _dashboard?.totalTrips?.toString() ?? '0',
                  'Trips',
                  Icons.local_taxi_rounded,
                  'All time',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _premiumStat(
                  (_dashboard?.acceptanceRate.toString() ?? '0') + '%',
                  'Acceptance',
                  Icons.access_time_filled_rounded,
                  'Rate',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _premiumStat(
                  '\$${_dashboard?.walletBalance ?? 0}',
                  'Wallet',
                  Icons.account_balance_wallet_rounded,
                  'Balance',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _premiumStat(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppConst.primaryColor),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.sp, color: Colors.black54),
          ),
        ],
      ),
    );
  }


  String _accountMessage() {
    final status = (_dashboard?.accountStatus ?? _accountStatus).toLowerCase();

    if (status == 'approved') {
      return 'Your account is approved and ready to drive.';
    }

    if (status == 'rejected') {
      return 'Your account needs attention. Please review your documents.';
    }

    return 'Your account is being reviewed by T-Ride.';
  }

  double _verificationProgress() {
    double progress = 0;

    if (_dashboard?.verified == true) progress += 0.30;
    if ((_dashboard?.approvedDocuments ?? 0) > 0) progress += 0.25;
    if ((_dashboard?.backgroundCheckStatus ?? '').toLowerCase() == 'approved') {
      progress += 0.25;
    }
    if ((_dashboard?.accountStatus ?? _accountStatus).toLowerCase() == 'approved') {
      progress += 0.20;
    }

    return progress.clamp(0, 1);
  }

  String _verificationPercent() {
    return '${(_verificationProgress() * 100).round()}%';
  }

  String _backgroundCheckLabel() {
    final status = (_dashboard?.backgroundCheckStatus ?? 'pending').toLowerCase();

    if (status == 'approved') return 'Approved';
    if (status == 'rejected') return 'Rejected';
    if (status == 'in_review') return 'In review';

    return 'Pending';
  }

  double _backgroundCheckProgress() {
    final status = (_dashboard?.backgroundCheckStatus ?? 'pending').toLowerCase();

    if (status == 'approved') return 1.0;
    if (status == 'rejected') return 0.15;
    if (status == 'in_review') return 0.65;

    return 0.35;
  }

  String _tierProgressLabel() {
    final tier = _dashboard?.tier ?? 'Standard';
    return '$tier';
  }

  double _tierProgressValue() {
    final tier = (_dashboard?.tier ?? 'Standard').toLowerCase();

    if (tier.contains('gold')) return 0.85;
    if (tier.contains('silver')) return 0.62;
    if (tier.contains('standard')) return 0.35;

    return 0.35;
  }

  Widget _statusCard() {
    return _sectionCard(
      title: 'Account status',
      icon: Icons.workspace_premium_rounded,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: Colors.green,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_dashboard?.accountStatus ?? _accountStatus).toUpperCase(),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _accountMessage(),
                      style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        _progressRow('Verification progress', _verificationPercent(), _verificationProgress()),
        SizedBox(height: 10.h),
        _progressRow('Background check', _backgroundCheckLabel(), _backgroundCheckProgress()),
        SizedBox(height: 10.h),
        _progressRow('Driver tier progress', _tierProgressLabel(), _tierProgressValue()),
      ],
    );
  }

  Widget _vehicleCard() {
    final hasVehicle =
        _carModel.isNotEmpty || _carPlate.isNotEmpty || _carColor.isNotEmpty;

    return _sectionCard(
      title: 'Vehicle information',
      icon: Icons.directions_car_filled_rounded,
      action: TextButton(onPressed: _openEditSheet, child: const Text('Edit')),
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  color: AppConst.primaryColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: AppConst.black,
                  size: 30.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: hasVehicle
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _carModel.isEmpty
                                ? 'Vehicle model not set'
                                : _carModel,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Plate: ${_carPlate.isEmpty ? 'Not set' : _carPlate}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Color: ${_carColor.isEmpty ? 'Not set' : _carColor}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Add vehicle details before accepting live trips.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _checkItem(
          'Vehicle registration uploaded',
          _vehicleRegistration != null,
        ),
        _checkItem('Insurance uploaded', _insurance != null),
        _checkItem('Vehicle photo uploaded', _vehiclePhoto != null),
        _checkItem('Inspection required for ride service', false),
      ],
    );
  }

  Future<void> _pickDocument(String type) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;

      setState(() {
        final file = File(picked.path);
        switch (type) {
          case 'license_front':
            _licenseFront = file;
            break;
          case 'license_back':
            _licenseBack = file;
            break;
          case 'insurance':
            _insurance = file;
            break;
          case 'vehicle_registration':
            _vehicleRegistration = file;
            break;
          case 'vehicle_photo':
            _vehiclePhoto = file;
            break;
          case 'profile_photo':
            _selectedPhoto = file;
            break;
        }
      });
    } catch (_) {
      AppSnackbar.showError(message: 'Unable to select document.');
    }
  }

  Future<void> _submitDriverDocuments() async {
    if (_uploadingDocs) return;

    if (_selectedPhoto == null &&
        _licenseFront == null &&
        _licenseBack == null &&
        _insurance == null &&
        _vehicleRegistration == null &&
        _vehiclePhoto == null) {
      AppSnackbar.showError(message: 'Please select at least one document.');
      return;
    }

    setState(() => _uploadingDocs = true);

    try {
      await _driverOnboardingRepository.uploadDocuments(
        profilePhoto: _selectedPhoto,
        licenseFront: _licenseFront,
        licenseBack: _licenseBack,
        insurance: _insurance,
        vehicleRegistration: _vehicleRegistration,
        vehiclePhoto: _vehiclePhoto,
      );

      if (_selectedPhoto != null) _documentStatuses['profile_photo'] = 'pending';
      if (_licenseFront != null) _documentStatuses['license_front'] = 'pending';
      if (_licenseBack != null) _documentStatuses['license_back'] = 'pending';
      if (_insurance != null) _documentStatuses['insurance'] = 'pending';
      if (_vehicleRegistration != null) _documentStatuses['vehicle_registration'] = 'pending';
      if (_vehiclePhoto != null) _documentStatuses['vehicle_photo'] = 'pending';

      if (!mounted) return;

      setState(() {
        if (_selectedPhoto != null) _documentStatuses['image'] = 'pending';
        if (_licenseFront != null) _documentStatuses['license_front'] = 'pending';
        if (_licenseBack != null) _documentStatuses['license_back'] = 'pending';
        if (_insurance != null) _documentStatuses['insurance'] = 'pending';
        if (_vehicleRegistration != null) _documentStatuses['vehicle_registration'] = 'pending';
        if (_vehiclePhoto != null) _documentStatuses['vehicle_photo'] = 'pending';

        _selectedPhoto = null;
        _licenseFront = null;
        _licenseBack = null;
        _insurance = null;
        _vehicleRegistration = null;
        _vehiclePhoto = null;
        _accountStatus = _dashboard?.accountStatus ?? 'pending_review';
      });

      AppSnackbar.showSuccess(
        message: 'Documents submitted. Your driver profile is pending review.',
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.showApiError(e);
      }
    } finally {
      if (mounted) setState(() => _uploadingDocs = false);
    }
  }


  String _docStatus(String key, File? localFile) {
    if (localFile != null) return 'Selected';

    final String? status = _documentStatuses[key];

    if (status == 'pending') return 'Pending';
    if (status == 'approved') return 'Valid';
    if (status == 'rejected') return 'Rejected';

    return 'Required';
  }

  Color _docStatusColor(String key, File? localFile) {
    if (localFile != null) return Colors.green;

    final String? status = _documentStatuses[key];

    if (status == 'pending') return Colors.orange;
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;

    return Colors.red;
  }

  Widget _documentsCard() {
    return _sectionCard(
      title: 'Driver verification',
      icon: Icons.shield_rounded,
      children: [
        _document(
          'Clear profile photo',
          _documentStatuses['profile_photo']?.toString().toUpperCase() ?? 'Required',
          Icons.person_rounded,
          (_documentStatuses['profile_photo'] == 'pending')
              ? Colors.orange
              : (_documentStatuses['profile_photo'] == 'approved')
                  ? Colors.green
                  : Colors.red,
          () => _pickDocument('profile_photo'),
        ),
        _document(
          'Driver license front',
          _documentStatuses['license_front']?.toString().toUpperCase() ?? 'Required',
          Icons.badge_rounded,
          (_documentStatuses['license_front'] == 'pending')
              ? Colors.orange
              : (_documentStatuses['license_front'] == 'approved')
                  ? Colors.green
                  : Colors.red,
          () => _pickDocument('license_front'),
        ),
        _document(
          'Driver license back',
          _documentStatuses['license_back']?.toString().toUpperCase() ?? 'Required',
          Icons.badge_outlined,
          (_documentStatuses['license_back'] == 'pending')
              ? Colors.orange
              : (_documentStatuses['license_back'] == 'approved')
                  ? Colors.green
                  : Colors.red,
          () => _pickDocument('license_back'),
        ),
        _document(
          'Insurance',
          _documentStatuses['insurance']?.toString().toUpperCase() ?? 'Required',
          Icons.description_rounded,
          (_documentStatuses['insurance'] == 'pending')
              ? Colors.orange
              : (_documentStatuses['insurance'] == 'approved')
                  ? Colors.green
                  : Colors.red,
          () => _pickDocument('insurance'),
        ),
        _document(
          'Vehicle registration',
          _documentStatuses['vehicle_registration']?.toString().toUpperCase() ?? 'Required',
          Icons.article_rounded,
          (_documentStatuses['vehicle_registration'] == 'pending')
              ? Colors.orange
              : (_documentStatuses['vehicle_registration'] == 'approved')
                  ? Colors.green
                  : Colors.red,
          () => _pickDocument('vehicle_registration'),
        ),
        _document(
          'Vehicle photo',
          _documentStatuses['vehicle_photo']?.toString().toUpperCase() ?? 'Required',
          Icons.directions_car_rounded,
          (_documentStatuses['vehicle_photo'] == 'pending')
              ? Colors.orange
              : (_documentStatuses['vehicle_photo'] == 'approved')
                  ? Colors.green
                  : Colors.red,
          () => _pickDocument('vehicle_photo'),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 46.h,
          child: ElevatedButton.icon(
            onPressed: _uploadingDocs ? null : _submitDriverDocuments,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: Text(
              _uploadingDocs ? 'Submitting...' : 'Submit documents for review',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConst.black,
              foregroundColor: AppConst.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _backgroundCheckCard() {
    return _sectionCard(
      title: 'Background check',
      icon: Icons.verified_user_rounded,
      children: [
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)],
            ),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.manage_search_rounded,
                      color: Colors.orange,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending review',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Powered by Checkr',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(40.r),
                    ),
                    child: Text(
                      'IN REVIEW',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: LinearProgressIndicator(
                  value: 0.48,
                  minHeight: 8.h,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(AppConst.primaryColor),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Estimated completion: 1-2 business days',
                style: TextStyle(fontSize: 11.sp, color: Colors.white70),
              ),
              SizedBox(height: 18.h),
              _bgStep('Identity verification', true),
              _bgStep('Driving record / MVR', false),
              _bgStep('Criminal background check', false),
              _bgStep('T-Ride final approval', _accountStatus == 'approved'),
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_moon_rounded,
                      color: AppConst.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'T-Ride verifies all active drivers to help keep the platform safe for riders and drivers.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bgStep(String title, bool done) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: done
                  ? Colors.green.withOpacity(0.18)
                  : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
              size: 15.sp,
              color: done ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String title, bool done) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? Colors.green : Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferencesCard() {
    return _sectionCard(
      title: 'Work preferences',
      icon: Icons.tune_rounded,
      children: [
        _toggleRow('Ride requests', _rideRequestsEnabled, (v) => _savePreferences(rideRequests: v)),
        _toggleRow('Bid & Ride', _bidEnabled, (v) => _savePreferences(bid: v)),
        _toggleRow('Pooling', _poolingEnabled, (v) => _savePreferences(pooling: v)),
        _toggleRow('Courier', _courierEnabled, (v) => _savePreferences(courier: v)),
        _toggleRow('Delivery', _deliveryEnabled, (v) => _savePreferences(delivery: v)),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pet Friendly',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _savePreferences(petFriendly: false),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Decline'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _savePreferences(petFriendly: true),
                      icon: const Icon(Icons.pets_rounded),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.primaryColor,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Future<void> _savePreferences({
    bool? rideRequests,
    bool? bid,
    bool? pooling,
    bool? courier,
    bool? delivery,
    bool? petFriendly,
  }) async {
    setState(() {
      if (rideRequests != null) _rideRequestsEnabled = rideRequests;
      if (bid != null) _bidEnabled = bid;
      if (pooling != null) _poolingEnabled = pooling;
      if (courier != null) _courierEnabled = courier;
      if (delivery != null) _deliveryEnabled = delivery;
      if (petFriendly != null) _petFriendlyEnabled = petFriendly;
    });

    try {
      await _dashboardRepository.updatePreferences(
        bidEnabled: _bidEnabled,
        poolingEnabled: _poolingEnabled,
        courierEnabled: _courierEnabled,
        deliveryEnabled: _deliveryEnabled,
        petFriendlyEnabled: _petFriendlyEnabled,
      );
    } catch (e) {
      AppSnackbar.showError(message: 'Unable to save preferences.');
    }
  }

  Widget _toggleRow(String title, bool enabled, ValueChanged<bool> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
          Switch(
            value: enabled,
            activeColor: AppConst.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _accountCard() {
    return _sectionCard(
      title: 'Account',
      icon: Icons.manage_accounts_rounded,
      children: [
        _menu(
          'Personal information',
          Icons.person_outline_rounded,
          _openEditSheet,
        ),
        _menu(
          'Earnings & payout',
          Icons.account_balance_wallet_outlined,
          () => AppSnackbar.showSuccess(
            title: 'Earnings',
            message: 'Ready for backend connection.',
          ),
        ),
        _menu(
          'Security',
          Icons.lock_outline_rounded,
          () => AppSnackbar.showSuccess(
            title: 'Security',
            message: 'Ready for backend connection.',
          ),
        ),
        _menu(
          'Help & support',
          Icons.support_agent_rounded,
          () => AppSnackbar.showSuccess(
            title: 'Support',
            message: 'Ready for backend connection.',
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    Widget? action,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConst.primaryColor, size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _progressRow(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7.h,
            backgroundColor: Colors.black.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(AppConst.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _document(
    String title,
    String subtitle,
    IconData icon,
    Color statusColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: AppConst.primaryColor),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                  ),
                ],
              ),
            ),
            Icon(Icons.circle, color: statusColor, size: 10.sp),
          ],
        ),
      ),
    );
  }

  Widget _menu(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppConst.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppConst.primaryColor.withOpacity(0.75),
      ),
      onTap: onTap,
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: _decoration(),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppConst.primaryColor.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}













