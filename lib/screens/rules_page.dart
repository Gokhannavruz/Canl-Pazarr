import 'package:flutter/material.dart';

class RulesPage extends StatefulWidget {
  const RulesPage({Key? key}) : super(key: key);

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Rules'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matching Rules:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '1 - Matching is entirely random. If a user has not selected a city or region, they may be matched with users from anywhere in the world.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 235, 219, 218),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '2 - If a user has selected only a country, they will be matched with users from that country. If they have selected both a country and a city, they will be matched with users from that city.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 235, 219, 218),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '3 - Matches will be made every two weeks. Users are expected to send their gifts within this two-week period.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 235, 219, 218),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "4 - It is entirely at the user's discretion to disclose their personal information and address to their matched user.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 235, 219, 218),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '5 - Users who do not wish to disclose their address can provide the address of the nearest shipping office.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 235, 219, 218),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '6 - As gifts are not monitored or controlled in any way, the app is not responsible for any gifts exchanged between users. All responsibility for gifts sent and received lies solely with the users.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 235, 219, 218),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
