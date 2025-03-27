import 'package:flutter/material.dart';
import 'package:managermoney/app/Accounts/editAccounts.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:get/get.dart';
import 'package:managermoney/widgets/crud.dart';

class AccountsList extends StatelessWidget {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  Future<dynamic> getAccounts() async {
    String userId = userController.getUserId();
    try {
      var response = await crud.postRequest(linkViewAccount, {
        "user_id": userId,
      });

      print("Raw Response: $response");

      if (response != null && response['status'] == "success") {
        return response;
      } else {
        print("Error retrieving accounts");
        return [];
      }
    } catch (e) {
      print("Error catch $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getAccounts(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No accounts found"));
        } else if (snapshot.hasData) {
          var data = snapshot.data['data'];
          if (data is List) {
            // Group the accounts by their 'group' field
            Map<String, List<Map<String, dynamic>>> groupedData = {};
            for (var item in data) {
              if (item is Map<String, dynamic>) {
                var group = item['group'] ?? "No Group";
                if (!groupedData.containsKey(group)) {
                  groupedData[group] = [];
                }
                groupedData[group]!.add(item);
              }
            }

            return ListView.builder(
              itemCount: groupedData.length,
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                var group = groupedData.keys.elementAt(index);
                var accounts = groupedData[group]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      // Accounts List for the Group
                      ListView.builder(
                        itemCount: accounts.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, i) {
                          var account = accounts[i];
                          var name = account['name'] ?? "No Name";
                          var amount = account['amount'] ?? "0";
                          var classification = account['classification'] ?? "No Classification";

                          // Determine the color based on classification
                          Color amountColor = Colors.black;
                          if (classification == "Assets") {
                            amountColor = Colors.blue;
                          } else if (classification == "Liabilities") {
                            amountColor = Colors.red;
                          }

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              // Combine name and amount in one row
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    amount,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: amountColor),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.edit, color: Colors.grey),
                              onTap: () {
                                Get.to(UpdateAccount(accountData: account));
                              },
                            ),
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: Text("Invalid data format"));
          }
        }
        return Container();
      },
    );
  }
}