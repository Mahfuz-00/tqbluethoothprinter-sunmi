import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footer/footer.dart';
import 'package:http/http.dart' as http;

import '../Constant/urls_and_token.dart';
import '../Sunmi T2s/sunmit2ssdk.dart';

class EnterDetailsPage extends StatefulWidget {
  final String authToken;
  final Map<String, dynamic> jsonBody;

  const EnterDetailsPage({
    Key? key,
    required this.authToken,
    required this.jsonBody
  }) : super(key: key);

  @override
  _EnterDetailsPageState createState() => _EnterDetailsPageState();
}

class _EnterDetailsPageState extends State<EnterDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  bool isFullScreen = false;

  IconData _getIcon() {
    return isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen;
  }

  @override
  void initState() {
    super.initState();
    // TODO: implement initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Your code that calls setState()
    });
/*    Future.delayed(const Duration(seconds: 1), () {
      // This attempts to pop any overlay dialog that might still be showing.
      // Using the root navigator ensures that you target dialogs/overlays.
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });*/
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double paddingValue = screenWidth * 0.06;

    return PopScope(
      canPop: false,
      child: Scaffold(
        // Optionally include a basic AppBar for navigation/back button only
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.black26,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Padding(
                padding: EdgeInsets.only(left: paddingValue),
                child: Image.asset(
                  'Assets/TQLogo.png',
                  height: screenHeight * 0.07,
                  width: screenWidth * 0.15,
                ),
              ),
              //),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: paddingValue + 2),
                  child: Visibility(
                    visible: !isFullScreen,
                    child: Container(
                      child: IconButton(
                        icon: Icon(_getIcon()),
                        onPressed: () {
                          setState(() {
                            isFullScreen = true;
                            print('isFullScreen: $isFullScreen');
                            if (isFullScreen) {
                              SystemChrome.setEnabledSystemUIMode(
                                  SystemUiMode.manual,
                                  overlays: []);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title inside the body with Bangla translation appended
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Enter Details (বিবরণ লিখুন)",
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Text field for Patient Name
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name (রোগীর নাম)',
                  ),
                ),
                const SizedBox(height: 10),
                // Text field for Mobile Number
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number (মোবাইল নম্বর)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                // Display error message if any
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                // Centered Print button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      primary: Theme.of(context).primaryColor,
                      fixedSize: Size(screenWidth * 0.25,
                          screenHeight * 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            10.0), // Adjust the radius as needed
                      ),
                    ),
                    onPressed: isLoading ? null : _handlePrint,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Print",
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          height: screenHeight * 0.075,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey,
                width: 1.0,
              ),
            ),
          ),
          child: Footer(
            backgroundColor: Colors.grey[200],
            padding: EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                    '©Copyright ${DateTime.now().year} Touch Queue. All Rights Reserved.'),
                SizedBox(
                  width: screenWidth * 0.35,
                ),
                Text('Developed and Maintained by: Touch and Solve'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrint() async {
    // Dismiss the keyboard
    // FocusScope.of(context).unfocus();

    // Validate that both fields are filled
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields (সব তথ্য পূরণ করুন)';
      });
      return;
    } else {
      setState(() {
        errorMessage = '';
      });
    }

    setState(() {
      isLoading = true;
    });

    widget.jsonBody.addAll({
      'name': nameController.text,
      'mobile_number': phoneController.text,
    });

    print('Input Json: ${widget.jsonBody}');


    // Build the API URL (assuming your URLs class provides this)
    final url = '${URLs().Basepath}/api/create-token';

    try {
      // Make the POST API call using the entered values
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': widget.authToken,
        },
        body: json.encode(widget.jsonBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Response data: ${responseData}');
        final data = responseData['data'];
        final token = data['token'];
        final time = data['time'];
        final categoryName = data['category'];
        final additionalData = data['additionalData'];
        print(
            'Token: $token, Time and Date: $time, Category: $categoryName, Additional Data: $additionalData');

        // Call the printReceipt function from your SDK
        final SunmiPosSdk sunmiPosSdk = SunmiPosSdk();
        bool printSuccess = await sunmiPosSdk.printReceipt(
          context,
          '$token',
          '$time',
          // nameController.text,
          '$categoryName', additionalData
        );

        // After printing is complete, pop the page back to the previous screen.
        if (printSuccess) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            errorMessage = 'Print failed. Please try again.';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to fetch data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
