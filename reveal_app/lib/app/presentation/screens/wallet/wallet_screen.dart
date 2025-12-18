import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;

// استدعاء المودل (تأكد من صحة المسار لديك)
import '../../../data/models/wallet_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool isLoading = true;
  WalletModel? walletData;
  
  // الألوان
  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    fetchWalletData();
  }

  Future<void> fetchWalletData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final String? token = await user.getIdToken();
      if (token == null) return;

      // استبدل <YOUR_USERNAME> باسمك الحقيقي (RevealSystem)
      final url = Uri.parse('https://RevealSystem.pythonanywhere.com/api/wallet/');
      
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            walletData = WalletModel.fromJson(data);
            isLoading = false;
          });
        }
      } else {
        print("Error: ${response.body}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("Connection Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء كما في الصورة العلوية

      // 1. الشريط العلوي
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "المحفظة",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        // زر القائمة (Hamburger)
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 30),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
      ),
      
      drawer: const Drawer(child: Center(child: Text("القائمة الجانبية"))),

      // 2. جسم الصفحة
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رسالة الترحيب (اسم المستخدم الحقيقي)
                  Align(
                    alignment: Alignment.centerRight,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Cairo'),
                        children: [
                          const TextSpan(text: "أهلاً وسهلاً، "),
                          TextSpan(
                            text: walletData?.fullName ?? "يا بطل",
                            style: TextStyle(color: tealColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // 3. بطاقة الرصيد الكبيرة (Teal Card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "قيمة المحفظة",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        // الرقم الحقيقي
                        Text(
                          "${walletData?.balance.toStringAsFixed(1) ?? '0.0'} د.ل",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: tealColor),
                        ),
                        const SizedBox(height: 20),
                        // زر شحن المحفظة
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tealColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // هنا تضع منطق الانتقال لصفحة الدفع الإلكتروني
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("خدمة الشحن الإلكتروني قادمة قريباً!")),
                              );
                            },
                            child: const Text(
                              "شحن المحفظة",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // عنوان القائمة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "العمليات المالية",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {}, // لفتح تقرير كامل
                        child: Text("تقرير >", style: TextStyle(color: tealColor)),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 4. قائمة المعاملات (List View)
                  if (walletData == null || walletData!.transactions.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("لا توجد عمليات سابقة", style: TextStyle(color: Colors.grey)),
                    ))
                  else
                    ListView.builder(
                      shrinkWrap: true, // مهم جداً داخل SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(), // لمنع السكرول الداخلي
                      itemCount: walletData!.transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(walletData!.transactions[index]);
                      },
                    ),
                ],
              ),
            ),

      // 5. الشريط السفلي (Wallet Active)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: tealColor,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: 4, // رقم 4 هو المحفظة حسب الترتيب في الصورة
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "الرئيسية"),
            const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: "السلة"),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "الحساب"),
            const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: "طلباتي"),
            // أيقونة المحفظة المميزة بالدائرة البرتقالية
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: orangeColor, 
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              ),
              label: "المحفظة",
            ),
          ],
        ),
      ),
    );
  }

  // تصميم كرت المعاملة الواحدة
  Widget _buildTransactionCard(WalletTransaction txn) {
    // تنسيق التاريخ الحقيقي
    final dateStr = intl.DateFormat('yyyy/MM/dd').format(txn.dateObj);
    
    // تحديد الإشارة (+ أو -)
    final isPurchase = txn.type == 'purchase';
    final amountSign = isPurchase ? "-" : "+";
    final amountColor = isPurchase ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // اللوجو (دائري)
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            backgroundImage: const NetworkImage("https://cdn-icons-png.flaticon.com/512/3063/3063822.png"), // صورة افتراضية أو شعار الكلية
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: orangeColor, width: 2), // الدائرة البرتقالية حول الشعار
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // تفاصيل العملية
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.collegeName.isNotEmpty ? txn.collegeName : txn.description,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr, // التاريخ الحقيقي المنسق
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          
          // المبلغ
          Text(
            "$amountSign${txn.amount.toStringAsFixed(0)} د.ل",
            style: TextStyle(
              color: amountColor, 
              fontWeight: FontWeight.bold, 
              fontSize: 16
            ),
            textDirection: TextDirection.ltr, // عشان الدينار يجي يسار أو يمين صح
          ),
        ],
      ),
    );
  }
}
