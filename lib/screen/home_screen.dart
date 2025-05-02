import 'dart:collection';
import 'package:echo/screen/profile_screen.dart';
import 'package:echo/widgets/app_drawer.dart';
import 'package:echo/widgets/calendar.dart';
import 'package:echo/widgets/recent_entry.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LinkedHashMap<DateTime, List<Event>> sampleEvents = LinkedHashMap.from({
    DateTime(2025, 4, 2): [Event("A")],
    DateTime(2025, 4, 3): [Event("A"), Event("B")],
    DateTime(2025, 4, 11): [Event("A"), Event("B"), Event("C")],
    DateTime(2025, 4, 16): [Event("X")],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              color: Theme.of(context).primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.all(0),
                    leading: Builder(
                      builder: (context) => IconButton(
                        icon: Image.asset('assets/icons/hamburger.png'),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                    title: Text(
                      "Echo",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                  name: "Aye Chan Aung",
                                  gmail: "ayechanaung@gmail.com")),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 3),
                        child: Icon(
                          color: Colors.white,
                          Icons.person_rounded,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Friday, 25 2025",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Good Day!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Aye Chan Aung",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 60),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_4,
                            color: Color(0xFF6E61FD), size: 25),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Calendar",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    CustomCalendar(events: sampleEvents),
                    SizedBox(height: 10),
                    const Text(
                      "Recent Entries",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    RecentEntryCard(
                      title: "Idea on String Theory",
                      date: "24 Thur, Apr 2025",
                      time: "12 : 24 PM",
                    ),
                    RecentEntryCard(
                      title: "Note on Relativity",
                      date: "21 Mon, Apr 2025",
                      time: "11 : 04 AM",
                    ),
                    Container(
                      height: 100,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bottomIconButton(Icons.image_outlined, () {
                  print("Left button tapped");
                }),
                _bottomIconButton(Icons.mic, () {
                  print("Center button tapped");
                }, isCenter: true),
                _bottomIconButton(Icons.upload_file, () {
                  print("Right button tapped");
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _bottomIconButton(IconData icon, VoidCallback onTap,
    {bool isCenter = false}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(100),
    child: Container(
      width: isCenter ? 80 : 60,
      height: isCenter ? 80 : 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child:
          Icon(icon, color: const Color(0xFF6E61FD), size: isCenter ? 32 : 26),
    ),
  );
}
