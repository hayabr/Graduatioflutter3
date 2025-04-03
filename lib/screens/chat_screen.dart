import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
  late User signedInUser;
class ChatScreen extends StatefulWidget {
  static const String screenRoute = 'chat_screen'; 

  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  
  String? messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        signedInUser = user;
        print("User: ${signedInUser!.email}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[900],
        title: Row(
          children: [
            Image.asset('images/logo.png', height: 25),
            SizedBox(width: 10),
            Text(
              'MessageMe',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
            icon: Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
           MessageStreamBuilder(),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.orange,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        hintText: 'Write your message here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText ?? '',
                        'sender': signedInUser?.email ?? 'Unknown',
                        'time':FieldValue.serverTimestamp()
                      });
                    },
                    child: Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStreamBuilder extends StatelessWidget {
  const MessageStreamBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return  StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('messages').orderBy('time').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.blue,
                    ),
                  );
                }

                List<MessageLine> messageWidgets = [];
                final messages = snapshot.data!.docs.reversed;
                for (var message in messages) {
                  final data = message.data() as Map<String, dynamic>;
                  
                  final messageText = data.containsKey('text') ? data['text'] : 'No text';
                  final messageSender = data.containsKey('sender') ? data['sender'] : 'Unknown sender';
                  final currentUser = signedInUser?.email;
                  if(currentUser == messageSender){

                  }

                  final messageWidget = MessageLine(sender: messageSender,
                  text: messageText,
                  isMe: currentUser == messageSender,
                  );
                  messageWidgets.add(messageWidget);
                }

                return Expanded(
                  child: ListView(
                    reverse: true,
                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
                    children: messageWidgets,
                  ),
                );
              },
            );
  }
}

class MessageLine extends StatelessWidget {
  const MessageLine({this.text,this.sender,required this.isMe ,Key?key}):super(key: key);

  final String? sender;
  final String? text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text('$sender', style: TextStyle(fontSize: 12,color: Colors.yellow[900]),),
          Material(
            elevation: 5,
            borderRadius: isMe? BorderRadius.only(
             topLeft: Radius.circular(30),
             bottomLeft: Radius.circular(30),
             bottomRight: Radius.circular(30),

            ):BorderRadius.only(
             topRight: Radius.circular(30),
             bottomLeft: Radius.circular(30),
             bottomRight: Radius.circular(30),

            ) ,
            color:isMe? Colors.blue[800]: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
              child: Text('$text'),
            )
            ),
        ],
      ),
    );
      style:TextStyle(fontSize: 15 ,color: isMe? Colors.white : Colors.black45);
  }
}