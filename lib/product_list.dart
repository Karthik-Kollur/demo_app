import 'dart:io';

import 'package:badges/badges.dart';
import 'package:demo_app/favorite_page.dart';
import 'package:demo_app/profile_page.dart';
import 'package:demo_app/service/auth_service.dart';
import 'package:demo_app/service/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'auth/login_page.dart';
import 'cart_model.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';
import 'db_helper.dart';
import 'helper/helper_function.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);



  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {

  int selectedIndex = 0;
  void _onItemTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }





  List<String> productName = [
    'Contraseptives',
    'Magnesium Pills',
    'Cough Syrup',
    'Pain Killers',
    'ARVs',
    'Health supplements and vitamins',
    'Skincare products',
  ];

  List<String> productUnit = [
    'Price',
    'Price',
    'Price',
    'Price',
    'Price',
    'Price',
    'Price',
  ];

  List<int> productPrice = [10, 20, 30, 40, 50, 60, 70];

  List<String> productImage = [
    'https://cdn.britannica.com/36/205236-131-C309B908/pill-pharmacy-counter-pills-strips-background.jpg',
    'https://m.media-amazon.com/images/I/71gSgExYP7L._AC_UF1000,1000_QL80_.jpg',
    'https://kagcare.com/product_images/1583554467Cough-Syrup.jpg',
    'https://4.imimg.com/data4/PN/AB/MY-6350025/tablets-painkiller-spilled-yellow-bottle-11878123-500x500.jpg',
    'https://media.istockphoto.com/id/1359178070/photo/antiretroviral-covid-pills-carton-box-tablets.jpg?s=612x612&w=0&k=20&c=M_DzZ5DJDdRml0-E9emdnHqPu-lvHJ7Mfj4Z51CalsI=',
    'https://www.getsupp.com/static/media/__resized/images/products/OM0BW3AKP95L8NWHX-5f6e53dc-fb19-4dc8-bb09-8c18f62c363f-thumbnail_webp-512x512-70.webp',
    'https://www.bigbasket.com/media/uploads/p/l/40083862_10-olay-total-effects-7-in-1-day-cream-normal-spf-15-rich-in-vitamin-b5-c-e.jpg',
  ];

  DBHelper? dbHelper = DBHelper();
  String userName = "";
  String email = "";
  AuthService authService = AuthService();

  Stream? userSnapshot;

  File? selectedImage;
  bool isImageSelected = false;
 

  @override
  void initState() {
    super.initState();
    gettingUserData();

    profilePic();
  }


  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  String getName(String res) {
    return res.substring(res.indexOf("_") + 1);
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
            await uploadTask.whenComplete(() => setState(() {
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
          return CircleAvatar(

            radius: 45,
            backgroundImage: NetworkImage(snapshot.data['profilePic']),
          );


        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(

      bottomNavigationBar: BottomNavigationBar(backgroundColor: Colors.white, items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home,color: Colors.blue,size: 30.0,),label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_outline,color: Colors.blue,size: 30.0,),label: 'Favorite'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined,color: Colors.blue,size: 30.0,),label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.person,color: Colors.blue,size: 30.0,),label: 'Profile')
      ],selectedItemColor: Colors.blue,currentIndex: selectedIndex,onTap: _onItemTap,),

      appBar: AppBar(
        title: Text('E-Pharmacy'),
        centerTitle: true,
        actions: [


          InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CartScreen()));
            },
            child: Center(
              child: badges.Badge(
                showBadge: true,
                badgeContent: Consumer<CartProvider>(
                  builder: (context, value, child) {
                    return Text(value.getCounter().toString(),
                        style: TextStyle(color: Colors.white));
                  },
                ),
                animationType: BadgeAnimationType.fade,
                animationDuration: Duration(milliseconds: 300),
                child: Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
          SizedBox(width: 20.0)
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            // SizedBox(height: 220.0,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 100.0,
                width: 200.0,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: Row(
                    children: [
                      isImageSelected
                          ? CircleAvatar(
                        radius: 45.0,
                        backgroundImage: FileImage(selectedImage!),
                      )
                          : Expanded(child: profilePic()),
                      SizedBox(width: 10.0),
                      Flexible(
                        child: Text(
                          userName,
                          overflow: TextOverflow.clip,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ),
            SizedBox(
              height: 10.0,
            ),
            Center(
                child: Text(
              "Categories",
              style: TextStyle(fontSize: 25.0),
            )),
            Divider(
              thickness: 3,
            ),
SizedBox(height: 480.0,),
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
                    Icon(Icons.logout_outlined,size: 40.0,color: Colors.red,),
                  ],
                )),
          ],
        ),
      ),
      body:

       selectedIndex == 0
        ? Column(
         children: [
           Expanded(
             child: ListView.builder(
                 itemCount: productName.length,
                 itemBuilder: (context, index) {
                   return Card(
                     child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             mainAxisAlignment: MainAxisAlignment.start,
                             crossAxisAlignment: CrossAxisAlignment.center,
                             mainAxisSize: MainAxisSize.max,
                             children: [
                               Image(
                                 height: 100,
                                 width: 100,
                                 image: NetworkImage(
                                     productImage[index].toString()),
                               ),
                               SizedBox(
                                 width: 10,
                               ),
                               Expanded(
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.start,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       productName[index].toString(),
                                       style: TextStyle(
                                           fontSize: 16,
                                           fontWeight: FontWeight.w500),
                                     ),
                                     SizedBox(
                                       height: 5,
                                     ),
                                     Text(
                                       productUnit[index].toString() +
                                           " " +
                                           r"$" +
                                           productPrice[index].toString(),
                                       style: TextStyle(
                                           fontSize: 16,
                                           fontWeight: FontWeight.w500),
                                     ),
                                     SizedBox(
                                       height: 5,
                                     ),
                                     Align(
                                       alignment: Alignment.centerRight,
                                       child: InkWell(
                                         onTap: () {
                                           print(index);
                                           print(index);
                                           print(productName[index].toString());
                                           print(productPrice[index].toString());
                                           print(productPrice[index]);
                                           print('1');
                                           print(productUnit[index].toString());
                                           print(productImage[index].toString());

                                           dbHelper!
                                               .insert(Cart(
                                               id: index,
                                               productId: index.toString(),
                                               productName:
                                               productName[index]
                                                   .toString(),
                                               initialPrice:
                                               productPrice[index],
                                               productPrice:
                                               productPrice[index],
                                               quantity: 1,
                                               unitTag: productUnit[index]
                                                   .toString(),
                                               image: productImage[index]
                                                   .toString()))
                                               .then((value) {
                                             cart.addTotalPrice(double.parse(
                                                 productPrice[index]
                                                     .toString()));
                                             cart.addCounter();

                                             final snackBar = SnackBar(
                                               backgroundColor: Colors.green,
                                               content: Text(
                                                   'Product is added to cart'),
                                               duration: Duration(seconds: 1),
                                             );

                                             ScaffoldMessenger.of(context)
                                                 .showSnackBar(snackBar);
                                           }).onError((error, stackTrace) {
                                             print("error" + error.toString());
                                             final snackBar = SnackBar(
                                                 backgroundColor: Colors.red,
                                                 content: Text(
                                                     'Product is already added in cart'),
                                                 duration: Duration(seconds: 1));

                                             ScaffoldMessenger.of(context)
                                                 .showSnackBar(snackBar);
                                           });
                                         },
                                         child: Container(
                                           height: 35,
                                           width: 100,
                                           decoration: BoxDecoration(
                                               color: Colors.green,
                                               borderRadius:
                                               BorderRadius.circular(5)),
                                           child: const Center(
                                             child: Text(
                                               'Add to cart',
                                               style: TextStyle(
                                                   color: Colors.white),
                                             ),
                                           ),
                                         ),
                                       ),
                                     )
                                   ],
                                 ),
                               ),
                             ],
                           )
                         ],
                       ),
                     ),
                   );
                 }),
           ),
         ],
       )
        : selectedIndex == 1
    ? FavoritePage()
        : selectedIndex == 2
    ? CartScreen()
        : selectedIndex == 3
    ? ProfilePage()

        : Container(),




    );
  }
}



