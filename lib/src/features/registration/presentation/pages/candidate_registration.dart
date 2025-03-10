import 'dart:typed_data';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_details.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_preference.dart';
import 'package:doormer/src/features/registration/presentation/bloc/document_upload/registration_document_bloc.dart';
import 'package:doormer/src/features/registration/presentation/bloc/registration/registration_bloc.dart';
import 'package:doormer/src/features/registration/presentation/widget/category_selection_card.dart';
import 'package:doormer/src/features/registration/utils/priority_multi_select_menu_controller.dart';
import 'package:doormer/src/shared/widget/custom_textfield_web.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CandidateRegistrationPage extends StatefulWidget {
  const CandidateRegistrationPage({super.key});

  @override
  State<CandidateRegistrationPage> createState() =>
      _CandidateRegistrationPageState();
}

class _CandidateRegistrationPageState extends State<CandidateRegistrationPage> {
  // Unified configuration for border appearance.
  static const Color unifiedBorderColor = Colors.grey;
  static const double unifiedBorderThickness = 1.0;
  // Unified configuration for button height.
  static const double unifiedButtonHeight = 35.0;

  // Shared configuration for multi-select menus.
  static const int kMaxSelection = 3;

  // Controllers for the multi-select menus (Candidate Preferences).
  final MultiSelectController _priority1Controller = MultiSelectController();
  final MultiSelectController _priority2Controller = MultiSelectController();
  final MultiSelectController _priority3Controller = MultiSelectController();
  final MultiSelectController _priority4Controller = MultiSelectController();
  final MultiSelectController _priority5Controller = MultiSelectController();

  // Controllers for candidate info text fields.
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Local state to update the UI accordingly.
  bool isDocumentUploaded = false;
  bool showDocumentError = false;
  String? documentErrorMessage;
  bool isFormValid = false;
  String? uploadedFileName;

  @override
  void initState() {
    super.initState();
    firstNameController.addListener(_validateForm);
    lastNameController.addListener(_validateForm);
    phoneNumberController.addListener(_validateForm);
    _priority1Controller.addListener(_validateForm);
    _priority2Controller.addListener(_validateForm);
    _priority3Controller.addListener(_validateForm);
    _priority4Controller.addListener(_validateForm);
    _priority5Controller.addListener(_validateForm);
  }

  @override
  void dispose() {
    _priority1Controller.dispose();
    _priority2Controller.dispose();
    _priority3Controller.dispose();
    _priority4Controller.dispose();
    _priority5Controller.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  /// Validates the phone number using NZ format rules.
  String? _validateNZPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final RegExp nzPhoneRegExp =
        RegExp(r'^(?:\+64\s?|0)2[0-2,6-9](\s|-|)\d{3,4}(\s|-|)\d{3,4}$');
    if (!nzPhoneRegExp.hasMatch(value)) {
      return 'Invalid phone number';
    }
    return null;
  }

  /// Validates the form and updates the state of the submit button.
  void _validateForm() {
    setState(() {
      isFormValid = firstNameController.text.isNotEmpty &&
          lastNameController.text.isNotEmpty &&
          phoneNumberController.text.isNotEmpty &&
          isDocumentUploaded &&
          _priority1Controller.selectedItems.length == kMaxSelection &&
          _priority2Controller.selectedItems.length == kMaxSelection &&
          _priority3Controller.selectedItems.length == kMaxSelection &&
          _priority4Controller.selectedItems.length == kMaxSelection &&
          _priority5Controller.selectedItems.length == kMaxSelection;
    });
  }

  /// Handles file selection and triggers the Upload event for the document.
  Future<void> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;
      if (!context.mounted) return;

      // Dispatch the Upload event to the RegistrationDocumentBloc.
      context.read<RegistrationDocumentBloc>().add(
            UploadRegistrationDocument(
              fileName: fileName,
              fileBytes: fileBytes,
            ),
          );
      // Update local state to reflect file upload and store file name.
      setState(() {
        isDocumentUploaded = true;
        showDocumentError = false;
        documentErrorMessage = null;
        uploadedFileName = fileName;
      });
      _validateForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegistrationBloc>(
          create: (_) => serviceLocator<RegistrationBloc>()
            ..add(const LoadRegistrationOptionsEvent()),
        ),
        BlocProvider<RegistrationDocumentBloc>(
          create: (_) => RegistrationDocumentBloc(),
        ),
      ],
      child: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            GoRouter.of(context).go('/auth/registration-complete');
          }
        },
        builder: (context, state) {
          // While loading or on error, show a full-screen message.
          if (state is RegistrationOptionsLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is RegistrationOptionsFailure) {
            return Scaffold(
              body: Center(child: Text('Error: ${state.errorMessage}')),
            );
          } else if (state is RegistrationOptionsLoaded) {
            final options = state.options;
            return Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  // Limit the maximum width to avoid stretching on large screens.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Candidate Information Section
                          const Text(
                            'Enter Information',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          // Passing unified border config to the text fields.
                          CustomTextFieldWeb(
                            label: 'First Name',
                            controller: firstNameController,
                            validator: (value) => value!.isEmpty
                                ? 'First name is required'
                                : null,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFieldWeb(
                            label: 'Last Name',
                            controller: lastNameController,
                            validator: (value) =>
                                value!.isEmpty ? 'Last name is required' : null,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                          ),
                          const SizedBox(height: 24),
                          CustomTextFieldWeb(
                            label: 'Phone Number',
                            controller: phoneNumberController,
                            keyboardType: TextInputType.phone,
                            validator: _validateNZPhoneNumber,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Upload CV (PDF) *Required',
                            style: AppTextStyles.bodyMedium,
                          ),
                          if (uploadedFileName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Uploaded: $uploadedFileName',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.005,
                            ),
                            width: double.infinity,
                            height: unifiedButtonHeight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.uploadButton,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              onPressed: () => _pickFile(context),
                              child: const Text(
                                'Upload CV',
                                style: AppTextStyles.buttonText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // CategorySelectionCard widgets with unified border config
                          // and unified button height.
                          CategorySelectionCard(
                            title: 'Roles',
                            description: 'Choose your top 3 roles',
                            options: List<String>.from(options['Role'] ?? []),
                            controller: _priority1Controller,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                            buttonHeight: unifiedButtonHeight,
                          ),
                          const SizedBox(height: 32),
                          CategorySelectionCard(
                            title: 'Industry',
                            description: 'Choose up to 3 industries',
                            options:
                                List<String>.from(options['Industry'] ?? []),
                            controller: _priority2Controller,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                            buttonHeight: unifiedButtonHeight,
                          ),
                          const SizedBox(height: 32),
                          CategorySelectionCard(
                            title: 'Company Size',
                            description: 'Choose up to 3 company sizes',
                            options:
                                List<String>.from(options['CompanySize'] ?? []),
                            controller: _priority3Controller,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                            buttonHeight: unifiedButtonHeight,
                          ),
                          const SizedBox(height: 32),
                          CategorySelectionCard(
                            title: 'Expectations',
                            description: 'Choose your top 3 expectations',
                            options:
                                List<String>.from(options['Expectation'] ?? []),
                            controller: _priority4Controller,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                            buttonHeight: unifiedButtonHeight,
                          ),
                          const SizedBox(height: 32),
                          CategorySelectionCard(
                            title: 'Culture',
                            description: 'Choose up to 3 cultures',
                            options:
                                List<String>.from(options['Culture'] ?? []),
                            controller: _priority5Controller,
                            borderColor: unifiedBorderColor,
                            borderThickness: unifiedBorderThickness,
                            buttonHeight: unifiedButtonHeight,
                          ),
                          const SizedBox(height: 32),
                          // Submit Button
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.01,
                            ),
                            width: double.infinity,
                            height: unifiedButtonHeight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFormValid
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                              onPressed: isFormValid
                                  ? () {
                                      final docState = context
                                          .read<RegistrationDocumentBloc>()
                                          .state;
                                      if (_formKey.currentState!.validate() &&
                                          docState
                                              is RegistrationDocumentUploaded) {
                                        final candidateDetails =
                                            CandidateDetails(
                                          firstName: firstNameController.text,
                                          lastName: lastNameController.text,
                                          mobileNumber:
                                              phoneNumberController.text,
                                        );
                                        final candidatePreference =
                                            CandidatePreference(
                                          role: _priority1Controller
                                              .selectedItems,
                                          industry: _priority2Controller
                                              .selectedItems,
                                          companySize: _priority3Controller
                                              .selectedItems,
                                          oriented: _priority4Controller
                                              .selectedItems,
                                          culture: _priority5Controller
                                              .selectedItems,
                                        );
                                        context
                                            .read<RegistrationBloc>()
                                            .add(RegisterCandidateEvent(
                                              candidateDetails:
                                                  candidateDetails,
                                              candidatePreference:
                                                  candidatePreference,
                                              cvBytes: docState.fileBytes,
                                              cvFileName: docState.fileName,
                                            ));
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                            'Please complete all required fields and upload CV',
                                          ),
                                        ));
                                      }
                                    }
                                  : null,
                              child: const Text('Submit',
                                  style: AppTextStyles.buttonText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
