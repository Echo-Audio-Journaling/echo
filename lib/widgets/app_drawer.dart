import 'package:flutter/material.dart';
 
class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                height: 120,
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      child: Image.asset(
                        "assets/images/echo_logo.png",
                        fit: BoxFit.cover,
                      ),
                      height: 50,
                      margin: EdgeInsets.symmetric(vertical: 20),
                    ),
                    Text(
                      "Transform your ideas!",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                onTap: () {},
                leading: Icon(Icons.shopping_bag_sharp),
                title: Text("All Journals"),
              ),
              Divider(),
              ListTile(
                onTap: () {},
                leading: Icon(Icons.book),
                title: Text("Terms and Conditions"),
              ),
              SizedBox(height: 450,),
              Divider(),
              ListTile(
                onTap: () {},
                leading: Icon(Icons.delete),
                title: Text("Delete Account"),
              ),
              Divider(),
              ListTile(
                onTap: () {},
                leading: Icon(Icons.logout),
                title: Text("Log Out"),
              ),
              Divider(),
            ],
          ),
        ),
      ),
    );
  }
}