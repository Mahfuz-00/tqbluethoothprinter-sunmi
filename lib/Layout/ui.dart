import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:footer/footer.dart';
import 'package:http/http.dart' as http;
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../API/apiservice.dart';
import '../Constant/urls_and_token.dart';
import '../Sunmi T2s/sunmit2ssdk.dart';
import 'enterdetails.dart';

class UIScreen extends StatefulWidget {
  UIScreen({Key? key}) : super(key: key);

  @override
  _UIScreenState createState() => _UIScreenState();
}

class _UIScreenState extends State<UIScreen> with WidgetsBindingObserver{
  final ApiService _apiService = ApiService();
  bool isFullScreen = false;
  int isLoadingIndex = -1;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool isback = false;
  String finalOption = '';
  late Future<Map<String, dynamic>> _dataFuture;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  ValueNotifier<String> screenchange = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dataFuture = _apiService.fetchData();
    initSdk();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App is in background
    } else if (state == AppLifecycleState.resumed) {
      // App has come to the foreground
      // Restart the app
      Restart.restartApp();
    }
  }


  Future<void> initSdk() async {
    try {
      await SunmiPosSdk.initSdk(context);
    } catch (e) {
      print('Error initializing SDK: $e');
    }
  }

  IconData _getIcon() {
    return isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen;
  }

  List<Map<String, dynamic>> selectionStack = [];
  List<Map<String, dynamic>> selectedItems = [];
  Map<String, dynamic> CompleteJson = {};

  void addToJson(int id, String name, String key, bool isFirst) {
    Map<String, dynamic> newJson = {};
    print('id: $id, name: $name, key: $key, isFirst: $isFirst');

    if (isFirst == true) {
      // Add category information
      newJson['category_id'] = id;
      newJson['category_name'] = name;
      newJson['sub_categories'] = {};

      print('newJson with $key: ${jsonEncode(newJson)}');

      CompleteJson['id'] = id;
      // CompleteJson['category_name'] = name;
      CompleteJson['sub_categories'] = [];

      print('CompleteJson with $key: ${jsonEncode(CompleteJson)}');
    } else {
      // Initialize the list to hold subcategories or children
      List<Map<String, dynamic>> itemsList = [];

      // Check if the selectedItem contains 'sub_categories' or 'children'
      // Iterate over the subcategories or children and add their id and name
      itemsList.add({
        'sub_category_id': id,
        'name': name,
      });

      // Add the list to newJson under the appropriate key
      if (itemsList.isNotEmpty) {
        newJson[key] = itemsList;
        print('newJson with $key: ${jsonEncode(newJson)}');

        CompleteJson['sub_categories'].addAll(itemsList);
        print('CompleteJson with $key: ${jsonEncode(CompleteJson)}');
      }
    }
  }

  String layer = 'categories';

  /* List<dynamic> getCurrentOptions(Map<String, dynamic> data) {
    if (selectionStack.isEmpty) {
      print('Called: $data');
      for (var category in data['categories']) {
        print('Category Name: ${category['name_en']}');
      }
      print(selectionStack);
 */ /*     setState(() {
        layer = 'categories';
      });*/ /*
      return data['categories'];
    } else {
      Map<String, dynamic> current = selectionStack.last;
      print(layer);
      print('Current $current');
      int currentId = current['id'];
      print(currentId);
      if (layer == 'sub_categories') {
        // Find the category with the matching id
        var category = data['categories'].firstWhere(
              (cat) => cat['id'] == currentId,
          orElse: () => null,
        );

        if (category != null && category.containsKey('sub_categories')) {
          return category['sub_categories'];
        } else {
          return [];
        }
   */ /*     return data['categories']['sub_categories'];*/ /*
      } else if (layer == 'children') {
        // Find the subcategory with the matching id
        var subcategory = data['sub_categories'].firstWhere(
              (subcat) => subcat['id'] == currentId,
          orElse: () => null,
        );

        if (subcategory != null && subcategory.containsKey('children')) {
          return subcategory['children'];
        } else {
          return [];
        }
        // return data['children'];
      } else {
        return [];
      }
    }
  }*/
  Map<String, dynamic> getCurrentOptions(Map<String, dynamic> data) {
    // If no selection has been made, return the top-level categories.
    if (selectionStack.isEmpty) {
      print('Layer: categories');
      layer = 'categories';
      return {
        'layer': 'categories',
        'options': data['categories'] ?? [],
      };
    }

    // Start traversal from the top-level categories.
    List<dynamic> currentList = data['categories'] ?? [];
    Map<String, dynamic> currentItem = {};

    // Traverse the hierarchy using the selectionStack.
    for (var selection in selectionStack) {
      currentItem = currentList.firstWhere(
        (item) => item['id'] == selection['id'],
        orElse: () => null,
      );
      if (currentItem == null) {
        // If the current selection cannot be found, return an empty result.
        return {
          'layer': 'unknown',
          'options': [],
        };
      }
      // Determine the next level options.
      if (currentItem.containsKey('sub_categories') &&
          (currentItem['sub_categories'] as List).isNotEmpty) {
        isback = true;
        currentList = currentItem['sub_categories'];
      } else if (currentItem.containsKey('children') &&
          (currentItem['children'] as List).isNotEmpty) {
        currentList = currentItem['children'];
      } else {
        // No further options available.
        currentList = [];
        break;
      }
    }

    // Identify the current layer.
    // String layer;
    if (currentItem.containsKey('sub_categories') &&
        (currentItem['sub_categories'] as List).isNotEmpty) {
      layer = 'sub_categories';
    } else if (currentItem.containsKey('children') &&
        (currentItem['children'] as List).isNotEmpty) {
      layer = 'children';
    } else {
      layer = '';
    }

    print('Layer: $layer');
    print('Current item: $currentItem');
    print('Current item Childern: ${currentItem['children']}');
    print('Layer right now : ${layer}');
    if (layer == 'sub_categories' && currentItem['sub_categories'] == null) {
      finalOption = currentItem['type'];
      print('Current Option: $finalOption');
      handleFinalOption(finalOption);
    } else if (layer == 'children' ||
        layer == '' ||
        layer == null && currentItem['children'] == null) {
      finalOption = currentItem['type'];
      print('Current Option: $finalOption');
      handleFinalOption(finalOption);
    }
    print('Options: $currentList');

    return {
      'layer': layer,
      'options': currentList,
    };
  }

  void handleSelection(Map<String, dynamic> selectedItem) {
    setState(() {
      if (layer == 'categories') {
        print(selectionStack);
        selectionStack.add(
            {'id': selectedItem['id'], 'name_en': selectedItem['name_en']});
        // print('selectedItems: ${jsonEncode(selectedItems)}');
        addToJson(
            selectedItem['id'], selectedItem['name_en'], 'categories', true);
        setState(() {
          layer = 'sub_categories';
        });
      } else if (layer == 'sub_categories') {
        selectionStack
            .add({'id': selectedItem['id'], 'name_en': selectedItem['name']});
        addToJson(
            selectedItem['id'], selectedItem['name'], 'sub_categories', false);
        setState(() {
          layer = 'children';
        });
      } else if (layer == 'children') {
        selectionStack
            .add({'id': selectedItem['id'], 'name_en': selectedItem['name']});
        addToJson(selectedItem['id'], selectedItem['name'], 'children', false);
      } /*else {
        print('Type? :${finalOption}');
        if (finalOption == 'data') {
          // Implement your printing logic here
          print('Printing: ${finalOption}');


          // Call the function without using await here
          fetchDataAndPrintReceipt(CompleteJson);

        } else {
          // Navigate to detail page
          */ /*    Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(item: selectedItem),
          ),
        );*/ /*
        }
      }*/
    });
  }

  void handleFinalOption(String FinalOption) {
    print('Type? : $FinalOption');
    if (FinalOption == 'data') {
      // screenchange.value = 'data';
      // Implement your printing logic here
      print('Printing: $FinalOption');

      // Call the function without using await here
      fetchDataAndPrintReceipt(CompleteJson);
    } else if (FinalOption == 'input') {
      screenchange.value = 'input';
      /*   setState(() {
        finalOption == 'input';
      });*/
      /*    final String authToken = URLs().token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate to detail page
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnterDetailsPage(
                authToken: authToken,
                jsonBody: CompleteJson,
              ),
            )).then((_) {
          // This callback is invoked after the EnterDetailsPage is popped
          if (mounted) {
            setState(() {
              CompleteJson.clear();
              isback = false;
              selectionStack.clear();
              layer = 'categories';
            });
          }
        });
      });*/
    }
  }

  Future<void> fetchDataAndPrintReceipt(
      Map<String, dynamic> completeJson) async {
    final String authToken = URLs().token;
    final url = '${URLs().Basepath}/api/create-token';

    print(completeJson);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$authToken',
        },
        body: json.encode(completeJson),
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
            '$categoryName',
            additionalData);

        // After printing is complete, pop the page back to the previous screen.
        if (printSuccess) {
          // Show dialog with token details
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: buildAlertDialog(token, time, '$categoryName'),
              );
            },
          );

          setState(() {
            CompleteJson.clear();
            isback = false;
            selectionStack.clear();
            layer = 'categories';
            screenchange.value = '';
          });
          // Navigator.of(context).pop();
        } else {
          // Show error dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: Text('Error printing receipt'),
              );
            },
          );
        }
      }
    } catch (error) {
      print('Error occurred: $error');
    }
  }

/*  void handleBack() {
    setState(() {
      if (selectionStack.isNotEmpty) {
        selectionStack.removeLast();
      }
    });
  }*/

  void handleBack() {
    setState(() {
      if (selectionStack.isNotEmpty) {
        // Remove the last selection from the stack
        selectionStack.removeLast();

        print('Complete Json : $CompleteJson');

        // If the selectionStack is now empty, reset the CompleteJson
        if (selectionStack.isEmpty) {
          setState(() {
            CompleteJson.clear();
            isback = false;
          });
        } else if (CompleteJson['sub_categories'].isNotEmpty) {
          CompleteJson['sub_categories'].removeLast();
        }

        print('Complete Json === $CompleteJson ===');
      }
    });
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

    CompleteJson.addAll({
      'name': nameController.text,
      'mobile_number': phoneController.text,
    });

    print('Input Json: ${CompleteJson}');

    final String authToken = URLs().token;
    // Build the API URL (assuming your URLs class provides this)
    final url = '${URLs().Basepath}/api/create-token';

    try {
      // Make the POST API call using the entered values
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authToken,
        },
        body: json.encode(CompleteJson),
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
            '$categoryName',
            additionalData);

        // After printing is complete, pop the page back to the previous screen.
        if (printSuccess) {
          // Show dialog with token details
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: buildAlertDialog(token, time, '$categoryName'),
              );
            },
          );


          setState(() {
            CompleteJson.clear();
            isback = false;
            selectionStack.clear();
            layer = 'categories';
            screenchange.value = '';
          });
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

  String? validateBangladeshiPhoneNumber(String? value) {
    // Regular expression to match Bangladeshi phone numbers
    final RegExp regExp = RegExp(r'^01[0-9]{9}$');
    if (value == null || value.isEmpty) {
      return 'Please enter a mobile number.';
    } else if (!regExp.hasMatch(value)) {
      return 'Please enter a valid mobile number.';
    }
    return null;
  }

/*  List<dynamic> getCurrentOptions(Map<String, dynamic> data) {
    if (selectionStack.isEmpty) {
      print('Called: $data');
      for (var category in data['categories']) {
        print('Category Name: ${category['name_en']}');
      }
      return data['categories'];
    } else {
      Map<String, dynamic> current = selectionStack.last;
      print('Current $current');
      if (current.containsKey('sub_categories')) {
        return current['sub_categories'];
      } else if (current.containsKey('children')) {
        return current['children'];
      } else {
        return [];
      }
    }
  }*/

/*  void handleSelection(Map<String, dynamic> selectedItem) {
    Map<String, dynamic> newJson = {};
    setState(() {
      selectedItems
          .add({'id': selectedItem['id'], 'name': selectedItem['name_en']});
      // Determine the level based on the selected item's keys
      if (selectedItem.containsKey('sub_categories') &&
          selectedItem['sub_categories'].isNotEmpty) {
        selectionStack.add({'id': selectedItem['id'], 'name': selectedItem['name']});
        // Add category and subcategories
        addToJson(newJson, selectedItem, 'sub_categories');
      } else if (selectedItem.containsKey('children') &&
          selectedItem['children'].isNotEmpty) {
        selectionStack.add({'id': selectedItem['id'], 'name': selectedItem['name']});
        // Add category and children
        addToJson(newJson, selectedItem, 'children');
      } else {
        // Add only category
        newJson['category_id'] = selectedItem['id'];
        newJson['category_name'] = selectedItem['name_en'];
        print('newJson with category: ${jsonEncode(newJson)}');
      }
    });
  }*/

  /*void addToJson(Map<String, dynamic> newJson, Map<String, dynamic> selectedItem, String key) {
    // Check if 'category_id' already exists in newJson to prevent multiple additions
    if (key == 'categories') {
      // Add category information
      newJson['category_id'] = selectedItem['id'];
      newJson['category_name'] = selectedItem['name_en'];
    }

    // Initialize the list to hold subcategories or children
    List<Map<String, dynamic>> itemsList = [];

    // Iterate over the selected item's subcategories or children
    for (var item in selectedItem[key]) {
      itemsList.add({
        'id': item['id'],
        'name': item['name_en'] ?? item['name'],
      });
    }

    // Add the list to newJson under 'subcategories'
    newJson['subcategories'] = itemsList;

    // Log the updated newJson
    print('newJson with $key: ${jsonEncode(newJson)}');
  }
*/

  /*void handleSelection(Map<String, dynamic> selectedItem) {
    Map<String, dynamic> newJson = {};
    setState(() {
      newJson['category_id'] = selectedItem['id'];
      newJson['category_name'] = selectedItem['name_en'];
      print('newJson with categories: ${jsonEncode(newJson)}');
      if (selectedItem.containsKey('sub_categories') &&
          selectedItem['sub_categories'].isNotEmpty) {
        List<Map<String, dynamic>> subCategoriesList = [];
        for (var subCategory in selectedItem['sub_categories']) {
          subCategoriesList.add({
            'id': subCategory['id'],
            'name': subCategory['name_en'] ?? subCategory['name'],
          });
        }
        newJson['subcategories'] = subCategoriesList;
        print('newJson with subcategories: ${jsonEncode(newJson)}');
      } else if (selectedItem.containsKey('children') &&
          selectedItem['children'].isNotEmpty) {
        List<Map<String, dynamic>> childrenList = [];
        for (var child in selectedItem['children']) {
          childrenList.add({
            'id': child['id'],
            'name': child['name_en'] ?? child['name'],
          });
        }
        newJson['subcategories'] = childrenList;
        print('newJson with children: ${jsonEncode(newJson)}');
      } else {
        if (selectedItem['type'] == 'data') {
          print('Complete JSON: ${jsonEncode(newJson)}');
        } else {
          // Navigate to detail page
          */ /*      Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(item: selectedItem),
            ),
          );*/ /*
        }
      }
    });
  }*/

/*  void handleSelection(Map<String, dynamic> selectedItem) {
    Map<String, dynamic> newJson = {};
    setState(() {
      selectedItems
          .add({'id': selectedItem['id'], 'name': selectedItem['name_en']});
      print('selectedItems ${selectedItem}');
      addToJson(newJson, selectedItem, 'categories');
      if (selectedItem.containsKey('sub_categories') &&
          selectedItem['sub_categories'].isNotEmpty) {
        selectionStack.add({'id': selectedItem['id'], 'name': selectedItem['name']});
        addToJson(newJson, selectedItem, 'sub_categories');
        print('selectedItems ${selectedItem}');
      } else if (selectedItem.containsKey('children') &&
          selectedItem['children'].isNotEmpty) {
        selectionStack.add({'id': selectedItem['id'], 'name': selectedItem['name']});
        print('selectedItems ${selectedItem}');
        addToJson(newJson, selectedItem, 'children');
      } else {
        if (selectedItem['type'] == 'data') {
          // Implement your printing logic here
          print('Printing: ${selectedItem['name']}');
        } else {
          // Navigate to detail page
     */ /*           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(item: selectedItem),
            ),
          );*/ /*
        }
      }
    });
  }*/

/*  void handleBack() {
    setState(() {
      if (selectionStack.isNotEmpty) {
        selectionStack.removeLast();
      }
    });
  }*/

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double paddingValue = screenWidth * 0.06;

    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
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
                  title: Padding(
                    padding: EdgeInsets.only(left: paddingValue),
                    child: Image.asset(
                      'Assets/TQLogo.png',
                      height: screenHeight * 0.07,
                      width: screenWidth * 0.15,
                    ),
                  ),
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
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ValueListenableBuilder<String>(
                valueListenable: screenchange,
                builder: (context, value, child) {
                  if (value != 'input') {
                    return SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: screenHeight * 0.05,
                            ),
                            Container(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'WELCOME (স্বাগতম)',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.025,
                                  ),
                                  const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Please Select an option(s) from below (নীচের থেকে একটি বিকল্প(গুলি) নির্বাচন করুন)',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: screenHeight * 0.05,
                            ),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _dataFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Center(
                                      child: Text(
                                          'Error: ${snapshot.error ?? "No data"}'));
                                }

                                final data = snapshot.data!;
                                final currentOptions = getCurrentOptions(data);
                                print('CO :${currentOptions['options']}');

                                if (currentOptions['options'] == null ||
                                    currentOptions['options'].isEmpty) {
                             /*     setState(() {
                                    CompleteJson.clear();
                                    isback = false;
                                    selectionStack.clear();
                                    layer = 'categories';
                                    value = '';
                                  });

                                  Fluttertoast.showToast(
                                    msg: "Complete Json:${CompleteJson}, Selection Stack:${selectionStack}, Layer:${layer}, Isback:${isback} Value: ${value}",
                                    toastLength: Toast.LENGTH_LONG, // Note: Toast.LENGTH_LONG typically lasts for 3.5 seconds
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 10, // For iOS and web, specify the duration in seconds
                                    backgroundColor: Colors.black,
                                    textColor: Colors.white,
                                    fontSize: 16.0,
                                  );*/

                                  return Container(
                                    color: Colors.white,
                                    child: CircularProgressIndicator(),
                                  );
                                } else{
                                  // print('Data: ${jsonEncode(currentOptions)}');

                                  return Column(
                                    children: [
                                      ListView.builder(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.1,
                                            vertical: 3),
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: currentOptions['options'].length,
                                        itemBuilder: (context, index) {
                                          final option =
                                          currentOptions['options'][index];
                                          return Column(
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fixedSize: Size(screenWidth * 0.7,
                                                      screenHeight * 0.12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(5),
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    handleSelection(option),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    '${option['name_en'] ?? option['name']} (${option['name_bn']})',
                                                    style: TextStyle(
                                                        fontSize: 25,
                                                        color: Colors.white),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              )
                                            ],
                                          );
                                        },
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      if (isback) ...[
                                        Center(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fixedSize: Size(screenWidth * 0.25,
                                                  screenHeight * 0.12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(5),
                                              ),
                                            ),
                                            onPressed: () => handleBack(),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .arrow_back_ios_new_outlined,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Back',
                                                    style: TextStyle(
                                                        fontSize: 25,
                                                        color: Colors.white),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      SizedBox(
                                        height: 20,
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            /*FutureBuilder<Map<String, dynamic>>(
                        future: _apiService.fetchData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Center(
                                child: Text('Error: ${snapshot.error ?? "No data"}'));
                          }
                          final String companyName =
                              snapshot.data!['company']?.name ?? '';
                          final List<dynamic> categoriesData =
                              snapshot.data!['categories'] ?? [];
                          final bool shouldDialog =
                              snapshot.data!['config']['collect_data'] ?? '';
                          print(shouldDialog);

                          return LayoutBuilder(
                            builder:
                                (BuildContext context, BoxConstraints constraints) {
                              return Column(
                                children: categoriesData.map<Widget>((category) {
                                  final String nameEn = category.nameEn;
                                  final String nameBn = category.nameBn;
                                  final String DocBn = category.DocBn;
                                  final String DocEn = category.DocEn;
                                  final String DocDesignation = category.DocDesignation;
                                  final String DocRoom = category.DocRoom;

                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Column(
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                              Theme.of(context).colorScheme.primary,
                                              fixedSize: Size(screenWidth * 0.8,
                                                  screenHeight * 0.1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                isLoadingIndex =
                                                    categoriesData.indexOf(category);
                                                showLoadingOverlay(context);
                                              });
                                              final int categoryID = category.id;
                                              // final String authToken = '16253100c9ba119436b8089c338cb86cf420a51c4ed4bb0626dcbac295b2fd66';
                                              final String authToken = URLs().token;
                                              if (shouldDialog == false) {
                                                final url =
                                                    '${URLs().Basepath}/api/create-token';
                                                final response = await http
                                                    .post(Uri.parse(url), headers: {
                                                  'Content-Type': 'application/json',
                                                  'Authorization': '$authToken',
                                                }, body: {
                                                  'id': categoryID,
                                                });
                                                if (response.statusCode == 200) {
                                                  final responseData =
                                                  json.decode(response.body);
                                                  print(responseData);
                                                  final data = responseData['data'];
                                                  final Token = data['token'];
                                                  final Time = data['time'];
                                                  print(
                                                      'Token: $Token, Time and Date: $Time');

                                                  final SunmiPosSdk sunmiPosSdk =
                                                  SunmiPosSdk();
                                                  await sunmiPosSdk.printReceipt(
                                                      context,
                                                      '$Token',
                                                      '$Time',
                                                      '$nameEn',
                                                      '$nameBn',
                                                      '$companyName',
                                                      shouldDialog,
                                                      '',
                                                      '',
                                                      '',
                                                      '');

                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return Center(
                                                        child: buildAlertDialog(Token,
                                                            Time, '$nameEn ($nameBn)'),
                                                      );
                                                    },
                                                  );

                                                  setState(() {
                                                    isLoadingIndex = -1;
                                                  });
                                                } else {
                                                  print(
                                                      'Failed to fetch data: ${response.statusCode}');
                                                }
                                              }
                                              else if (shouldDialog == true) {
                                                */ /* closeLoadingOverlay(context);*/ /*
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EnterDetailsPage(
                                                            authToken: authToken,
                                                            categoryID: categoryID,
                                                            nameBn: nameBn,
                                                            nameEn: nameEn,
                                                            shouldDialog: shouldDialog,
                                                            DocEn: DocEn,
                                                            DocBn: DocBn,
                                                            DocDesignation: DocDesignation,
                                                            DocRoom: DocRoom,
                                                          ),
                                                    ));
                                              }
                                            },
                                            child: shouldDialog
                                                ? FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    '$DocEn ($DocBn), $DocDesignation, Room No (রুম নং): $DocRoom',
                                                    style: TextStyle(
                                                        fontSize: 25,
                                                        color: Colors.white),
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    '$nameEn ($nameBn)',
                                                    style: const TextStyle(
                                                      fontSize: 25,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                ],
                                              ),
                                            )
                                                : FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '$nameEn ($nameBn)',
                                                style: const TextStyle(
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.01),
                                        ],
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),*/
                          ],
                        ),
                      ),
                    );
                  } else if (value == 'input') {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
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
                                validator: validateBangladeshiPhoneNumber,
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
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                        primary: Theme.of(context).primaryColor,
                                        fixedSize: Size(
                                            screenWidth * 0.25, screenHeight * 0.12),
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
                                    SizedBox(width: 20,),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        primary: Theme.of(context).primaryColor,
                                        fixedSize: Size(
                                            screenWidth * 0.25, screenHeight * 0.12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              10.0), // Adjust the radius as needed
                                        ),
                                      ),
                                      onPressed: () {
                                        Restart.restartApp();
                                      },
                                      child: const Text(
                                              "Refresh",
                                              style: const TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Container(
                    color: Colors.white,
                    child: CircularProgressIndicator(),
                  );
                },
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
                    Row(
                      children: [
                        Text('Developed and Maintained by: '),
                        Image.asset(
                          'Assets/TNS_Logo.png',
                          width: 25,
                          height: 25,
                        ),
                        Text('Touch and Solve'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildAlertDialog(String token, String time, String name) {
    return AlertDialog(
      iconPadding: EdgeInsets.only(top: 15),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      icon: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.height * 0.2,
          child: Image.asset(
            'Assets/Success.gif',
            fit: BoxFit.contain,
          ),
        ),
      ),
      title: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Your Token No: $token',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '$name',
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.1,
              width: MediaQuery.of(context).size.width * 0.1,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    layer = 'categories';
                  });
                  /*    Future.delayed(Duration(milliseconds: 10), () {
                    closeLoadingOverlay(context);
                  });*/
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    return Theme.of(context).colorScheme.primary;
                  }),
                  /*textStyle: MaterialStateProperty.all(
                    TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),*/
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Add a border for visibility
                    ),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void closeLoadingOverlay(BuildContext context) {
    Navigator.of(context).pop();
  }
}
