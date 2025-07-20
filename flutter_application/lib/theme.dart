import 'package:flutter/material.dart';

class AppTheme {
   static const Color defaultIconColor = Colors.green;
  static const Color secondaryIconColor = Colors.orange; // NEW
  static const Color itemColor = Colors.grey;
   static const Color boxColor = Color.fromARGB(51, 76, 175, 79);
  static const Color cardColor = Color.fromARGB(255, 61, 23, 127);

  static ThemeData darkTheme({
    Color primaryButtonColor = const Color.fromARGB(255, 246, 141, 141),
    Color backgroundColor=const Color.fromARGB(255, 226, 238, 227),
    Color textColor = const Color(0xFF34495E), 
    Color textColor2=Colors.green,
   
  }) {
    return ThemeData(
      fontFamily: 'Quicksand', // Your custom font family
      primaryColor: primaryButtonColor,
      scaffoldBackgroundColor: Colors.white,
       bottomAppBarTheme: BottomAppBarTheme(
    color: backgroundColor, 
  ),
      hintColor: primaryButtonColor,
      iconTheme: const IconThemeData(color: defaultIconColor),
      appBarTheme: _buildAppBarTheme(primaryButtonColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(primaryButtonColor),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        labelStyle: TextStyle(color: Colors.white),
      ),

      // Set your text theme with your custom text color and font family
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor,fontWeight: FontWeight.bold,fontSize: 24),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor,fontSize: 14),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 24),
        titleMedium: TextStyle(color: textColor2, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: TextStyle(color: textColor2,fontWeight: FontWeight.bold,fontSize: 20,),
        bodyLarge: TextStyle(color: textColor,fontWeight: FontWeight.bold,  fontSize: 20),
        bodyMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        bodySmall: TextStyle(color: textColor, fontWeight: FontWeight.bold,fontSize: 14),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: textColor),
        labelSmall: TextStyle(color: textColor),
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color primaryButtonColor) {
    return const AppBarTheme(
      color: Colors.white,
        iconTheme:  IconThemeData(color: defaultIconColor),
    );
  }

  // You can still keep these if you want to reuse
  static TextStyle appBarTitleStyle = const TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle buttonTextStyle = const TextStyle(
    color: Colors.white,
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
  );

  static InputDecoration textInputDecoration({String labelText = ''}) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    );
  }
}
