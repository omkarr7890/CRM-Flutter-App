import 'package:flutter/material.dart';

class LeaveApplicationPage extends StatefulWidget {
  const LeaveApplicationPage({super.key});

  @override
  State<LeaveApplicationPage> createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController daysController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  String? leaveType;
  String? approval;
  String? finalApproval;

  DateTime? fromDate;
  DateTime? toDate;

  final List<String> leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Emergency Leave',
  ];

  final List<String> approvalOptions = [
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void dispose() {
    daysController.dispose();
    typeController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'dd/mm/yyyy';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> selectDate(bool isFromDate) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (fromDate ?? now) : (toDate ?? fromDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isFromDate) {
        fromDate = picked;

        if (toDate != null && toDate!.isBefore(picked)) {
          toDate = null;
        }
      } else {
        toDate = picked;
      }

      calculateDays();
    });
  }

  void calculateDays() {
    if (fromDate == null || toDate == null || toDate!.isBefore(fromDate!)) {
      daysController.clear();
      return;
    }

    daysController.text = (toDate!.difference(fromDate!).inDays + 1).toString();
  }

  InputDecoration decoration({Widget? suffixIcon}) {
    return InputDecoration(
      isDense: true,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFD5DDE4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget textField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 12),
          decoration: decoration(),
          validator: validator,
        ),
      ],
    );
  }

  Widget dateField(String label, DateTime? date, bool isFromDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        InkWell(
          onTap: () => selectDate(isFromDate),
          child: InputDecorator(
            decoration: decoration(
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 14,
              ),
            ),
            child: Text(
              formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: date == null ? Colors.black54 : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget dropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          decoration: decoration(),
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  void submitApplication() {
    if (!_formKey.currentState!.validate()) return;

    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select From Date and To Date'),
        ),
      );
      return;
    }

    if (toDate!.isBefore(fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('To Date cannot be before From Date'),
        ),
      );
      return;
    }

    // TODO: Integrate your Leave Application API here.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form validated successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 44,
              color: const Color(0xFFBCEBFA),
              padding: const EdgeInsets.only(left: 15, right: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Apply for Leave',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 19),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dropdownField(
                        label: 'Leave Type',
                        hint: '-- Select leave type --',
                        value: leaveType,
                        items: leaveTypes,
                        onChanged: (value) {
                          setState(() {
                            leaveType = value;
                            typeController.text = value ?? '';
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Select leave type' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: dateField(
                              'From Date',
                              fromDate,
                              true,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: dateField(
                              'To Date',
                              toDate,
                              false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: textField(
                              'No. of Days',
                              daysController,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 2,
                            child: textField(
                              'Type of Leave',
                              typeController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      textField(
                        'Reason',
                        reasonController,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter reason'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      dropdownField(
                        label: 'Approval',
                        hint: '--Select One--',
                        value: approval,
                        items: approvalOptions,
                        onChanged: (value) {
                          setState(() => approval = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      dropdownField(
                        label: 'Final Approval',
                        hint: '--Select One--',
                        value: finalApproval,
                        items: approvalOptions,
                        onChanged: (value) {
                          setState(() => finalApproval = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFD5DDE4)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C757D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: submitApplication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF198754),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
