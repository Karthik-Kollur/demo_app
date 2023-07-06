import 'package:demo_app/service/auth_service.dart';
import 'package:demo_app/service/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'auth/login_page.dart';
import 'helper/helper_function.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String userName = "";
  String email = "";
  Stream? userSnapshot;
  File? selectedImage;
  bool isImageSelected =false;
  bool isHovered = false;
  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    gettingUserData();

    // isImageSelected=true;
  }


  gettingUserData() async {
    await HelperFunctions.getUserEmailFromSF().then((value) {
      setState(() {
        email = value!;
      });
    });
    await HelperFunctions.getUserNameFromSF().then((val) {
      setState(() {
        userName = val!;
      });
    });

    await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserSnapshot()
        .then((snapshot) {
      setState(() {
        userSnapshot = snapshot;
      });
    });
  }

  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() async {
        selectedImage = File(image.path);
        isImageSelected = true;

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('/profile_picture/profile_picture_$userName');
        UploadTask uploadTask = ref.putFile(File(image.path));
        TaskSnapshot snapshot =
        await uploadTask.whenComplete(() =>
            setState(() {
              isImageSelected = true;
              // Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile Pic Updated ')));
            }));
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .savingProfilePic(downloadUrl);
      });
    }
  }

  Widget profilePic() {
    return StreamBuilder(
      stream: userSnapshot,
      builder: (context, AsyncSnapshot snapshot) {
        // make some checks
        if (snapshot.hasData) {
          print(snapshot.data);
          return Stack(
            children: [
              CircleAvatar(
                radius: 75,
                backgroundImage: NetworkImage(snapshot.data['profilePic']),
                child: MouseRegion(
                  onEnter: (event) {
                    setState(() {
                      isHovered = true;
                    });
                  },
                  onExit: (event) {
                    setState(() {
                      isHovered = false;
                    });
                  },
                  child: Visibility(
                    visible: isHovered,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(75),
                      ),
                      child: Center(
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 3,
                child: Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Theme
                  .of(context)
                  .primaryColor,
            ),
          );
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              pickImage();
            },
            child: isImageSelected
                ? Stack(
              children: [
                CircleAvatar(
                  radius: 75,
                  backgroundImage: FileImage(selectedImage!),
                ),
                Positioned(
                  right: 18,
                  bottom: 3,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
                : MouseRegion(
              onEnter: (PointerEvent details) {
                setState(() {
                  isHovered = true;
                });
              },
              onExit: (PointerEvent details) {
                setState(() {
                  isHovered = false;
                });
              },
              child: profilePic(),
            ),

          ),
          SizedBox(height: 30.0,),
          Text(
            userName,
            style: TextStyle(
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10.0,),
          Text(email,style: TextStyle(fontSize: 20.0),),
          SizedBox(height: 60.0,),
          GestureDetector(
              onTap: () async {
                await authService.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginPage()),
                        (route) => false);
              },
              child: Row(
                // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Logout",style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold),),
                  SizedBox(width: 10.0,),
                  Icon(Icons.logout_outlined,size: 60.0,color: Colors.red,),
                ],
              )),
        ],
      ),
    );
  }
}

