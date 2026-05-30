import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zhippay E-Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7E3FF2)),
        useMaterial3: true,
      ),
      home: const AuthStateWrapper(),
    );
  }
}

class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const OnboardingScreen();
      }
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: Container(
                    width: 220,
                    height: 380,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EAFD),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 340,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7E3FF2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "\$4,5790.00",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "zhippay",
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Your next generation of\nfinancial platform",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Simple user experience meets personal finance of the future backed by decentralized finance",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF7E3FF2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7E3FF2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Sign up to zhippay",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    debugPrint("LOGIN_START: Email = $email");
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      debugPrint("LOGIN_SUCCESS");
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("LOGIN_ERROR: $e");
      _logger.e("Login error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đăng nhập thất bại: $e")),
        );
      }
    } finally {
      debugPrint("LOGIN_FINALLY");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    debugPrint("REGISTER_START: Email = $email");
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("REGISTER_AUTH_SUCCESS: uid = ${credential.user?.uid}");
      final uid = credential.user!.uid;
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'displayName': email.split('@')[0],
        'balance': 5000.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("REGISTER_FIRESTORE_USER_SET_CALLED");
      final batch = FirebaseFirestore.instance.batch();
      final trans1 = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(trans1, {
        'uid': uid,
        'type': 'topup',
        'amount': 150.0,
        'description': 'Deposit',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'isIncome': true,
      });
      final trans2 = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(trans2, {
        'uid': uid,
        'type': 'withdraw',
        'amount': 232.80,
        'description': 'Cardless withdraw',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'isIncome': false,
      });
      final trans3 = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(trans3, {
        'uid': uid,
        'type': 'transfer',
        'amount': 170.09,
        'description': 'Bank transfer to Greg Stan',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'isIncome': false,
      });
      batch.commit();
      debugPrint("REGISTER_FIRESTORE_BATCH_COMMITTED_CALLED");
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("REGISTER_ERROR: $e");
      _logger.e("Registration error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đăng ký thất bại: $e")),
        );
      }
    } finally {
      debugPrint("REGISTER_FINALLY");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác thực zhippay", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E3FF2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Đăng nhập"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _register,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7E3FF2),
                side: const BorderSide(color: Color(0xFF7E3FF2)),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Đăng ký tài khoản mới"),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const WalletScreen(),
    const StatisticScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF7E3FF2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistic"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _logger = Logger();

  void _showTransactionDialog(BuildContext context, String title, String actionType) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Số tiền (\$)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountStr = amountController.text.trim();
              if (amountStr.isEmpty) return;
              final amount = double.tryParse(amountStr);
              if (amount == null || amount <= 0) return;
              Navigator.pop(context);
              
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
              try {
                double currentBalance = 5000.0;
                try {
                  final doc = await userRef.get(const GetOptions(source: Source.cache));
                  if (doc.exists) {
                    currentBalance = (doc.data()?['balance'] ?? 5000.0).toDouble();
                  }
                } catch (_) {
                  try {
                    final doc = await userRef.get();
                    if (doc.exists) {
                      currentBalance = (doc.data()?['balance'] ?? 5000.0).toDouble();
                    }
                  } catch (_) {}
                }
                
                double newBalance = currentBalance;
                if (actionType == 'topup') {
                  newBalance += amount;
                } else {
                  if (currentBalance < amount) {
                    throw Exception("Số dư không đủ");
                  }
                  newBalance -= amount;
                }
                
                userRef.update({'balance': newBalance});
                
                final transRef = FirebaseFirestore.instance.collection('transactions').doc();
                transRef.set({
                  'uid': user.uid,
                  'type': actionType,
                  'amount': amount,
                  'description': actionType == 'topup' ? 'Deposit' : 'Cardless withdraw',
                  'timestamp': FieldValue.serverTimestamp(),
                  'isIncome': actionType == 'topup',
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Giao dịch thành công")),
                  );
                }
              } catch (e) {
                _logger.e("Transaction error: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e")),
                  );
                }
              }
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "zhippay",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF7E3FF2)),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.card_giftcard, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text("rewards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.notifications_none, color: Colors.black87),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text("Lỗi tải thông tin số dư");
                  }
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final balance = data?['balance'] ?? 0.0;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7E3FF2), Color(0xFF5A3FFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7E3FF2).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total balance",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.stars, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text("6.350 points", style: TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$${balance.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionItem(context, Icons.add_circle_outline, "Top Up", () {
                              _showTransactionDialog(context, "Nạp tiền", "topup");
                            }),
                            _buildActionItem(context, Icons.swap_horiz, "Transfer", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SendMoneyScreen(currentBalance: balance),
                                ),
                              );
                            }),
                            _buildActionItem(context, Icons.arrow_downward, "Withdraw", () {
                              _showTransactionDialog(context, "Rút tiền", "withdraw");
                            }),
                            _buildActionItem(context, Icons.history, "History", () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Lịch sử giao dịch ở danh sách bên dưới nha bà!")),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1EAFD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rocket_launch, color: Color(0xFF7E3FF2), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Upgrade Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("upgrade account for more features", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Transfer again",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildAvatarItem("+ Add new", Icons.add, null, context),
                    _buildAvatarItem("Skyler", null, "S", context),
                    _buildAvatarItem("Andrew", null, "A", context),
                    _buildAvatarItem("Lavender", null, "L", context),
                    _buildAvatarItem("Grace", null, "G", context),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Latest transaction",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("see all", style: TextStyle(color: Color(0xFF7E3FF2))),
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('uid', isEqualTo: user.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Không thể tải danh sách giao dịch"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text("Chưa có giao dịch nào gần đây"));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final type = data['type'] ?? '';
                      final amount = data['amount'] ?? 0.0;
                      final description = data['description'] ?? '';
                      final isIncome = data['isIncome'] ?? false;
                      
                      IconData iconData = Icons.payment;
                      if (type == 'topup') {
                        iconData = Icons.call_received;
                      } else if (type == 'withdraw') {
                        iconData = Icons.call_made;
                      } else if (type == 'transfer') {
                        iconData = Icons.swap_horiz;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1EAFD),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: const Color(0xFF7E3FF2), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    type.toUpperCase(),
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAvatarItem(String name, IconData? icon, String? initials, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (initials != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SendMoneyScreen(
                currentBalance: 5000.0,
                recipientName: name,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFF1EAFD),
              child: icon != null
                  ? Icon(icon, color: const Color(0xFF7E3FF2))
                  : Text(initials!, style: const TextStyle(color: Color(0xFF7E3FF2), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  final _logger = Logger();

  void _processTransaction(String actionType) async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      double currentBalance = 5000.0;
      try {
        final doc = await userRef.get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          currentBalance = (doc.data()?['balance'] ?? 5000.0).toDouble();
        }
      } catch (_) {
        try {
          final doc = await userRef.get();
          if (doc.exists) {
            currentBalance = (doc.data()?['balance'] ?? 5000.0).toDouble();
          }
        } catch (_) {}
      }
      
      double newBalance = currentBalance;
      if (actionType == 'topup') {
        newBalance += amount;
      } else {
        if (currentBalance < amount) {
          throw Exception("Số dư không đủ");
        }
        newBalance -= amount;
      }
      
      userRef.update({'balance': newBalance});
      
      final transRef = FirebaseFirestore.instance.collection('transactions').doc();
      transRef.set({
        'uid': user.uid,
        'type': actionType,
        'amount': amount,
        'description': actionType == 'topup' ? 'Deposit' : 'Cardless withdraw',
        'timestamp': FieldValue.serverTimestamp(),
        'isIncome': actionType == 'topup',
      });
      
      _amountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giao dịch thành công")),
        );
      }
    } catch (e) {
      _logger.e("Transaction error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF7E3FF2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final balance = data?['balance'] ?? 0.0;
                    return Column(
                      children: [
                        const Text("Số dư khả dụng", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          "\$${balance.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xFF7E3FF2)),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Số tiền giao dịch (\$)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processTransaction('topup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Nạp tiền"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processTransaction('withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.remove),
                    label: const Text("Rút tiền"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  String _selectedRange = '1 Month';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    DateTime limitDate = DateTime.now();
    if (_selectedRange == '1 Month') {
      limitDate = DateTime.now().subtract(const Duration(days: 30));
    } else if (_selectedRange == '3 Months') {
      limitDate = DateTime.now().subtract(const Duration(days: 90));
    } else if (_selectedRange == '1 Year') {
      limitDate = DateTime.now().subtract(const Duration(days: 365));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistic", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF7E3FF2),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Thống kê dòng tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                DropdownButton<String>(
                  value: _selectedRange,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRange = value;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: '1 Month', child: Text("1 Tháng")),
                    DropdownMenuItem(value: '3 Months', child: Text("1 Quý (3T)")),
                    DropdownMenuItem(value: '1 Year', child: Text("1 Năm")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('uid', isEqualTo: user.uid)
                    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(limitDate))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Lỗi tải biểu đồ"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text("Không có dữ liệu thống kê trong khoảng thời gian này"));
                  }
                  
                  double totalIncome = 0.0;
                  double totalExpense = 0.0;
                  
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = data['amount'] ?? 0.0;
                    final isIncome = data['isIncome'] ?? false;
                    if (isIncome) {
                      totalIncome += amount;
                    } else {
                      totalExpense += amount;
                    }
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendCard("Thu nhập", totalIncome, Colors.green),
                          _buildLegendCard("Chi tiêu", totalExpense, Colors.red),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, top: 16),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: totalIncome,
                                      color: Colors.green,
                                      width: 24,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: totalExpense,
                                      color: Colors.red,
                                      width: 24,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                ),
                              ],
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() == 0) {
                                        return const Text("Thu nhập", style: TextStyle(fontWeight: FontWeight.bold));
                                      } else if (value.toInt() == 1) {
                                        return const Text("Chi tiêu", style: TextStyle(fontWeight: FontWeight.bold));
                                      }
                                      return const Text("");
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendCard(String label, double val, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("\$${val.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();

  void _updateProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': newName,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thông tin thành công")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF7E3FF2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFF1EAFD),
                child: Icon(Icons.person, size: 50, color: Color(0xFF7E3FF2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              user.email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final currentName = data['displayName'] ?? '';
                  if (_nameController.text.isEmpty && currentName.isNotEmpty) {
                    _nameController.text = currentName;
                  }
                }
                return TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Tên hiển thị",
                    border: OutlineInputBorder(),
                  ),
                );
              }
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E3FF2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Cập nhật thông tin"),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => FirebaseAuth.instance.signOut(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Đăng xuất"),
            ),
          ],
        ),
      ),
    );
  }
}

class SendMoneyScreen extends StatefulWidget {
  final double currentBalance;
  final String? recipientName;

  const SendMoneyScreen({super.key, required this.currentBalance, this.recipientName});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  String _amount = "0";
  String _selectedRecipient = "Amazon";
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    if (widget.recipientName != null) {
      _selectedRecipient = widget.recipientName!;
    }
  }

  void _onKeyPress(String val) {
    setState(() {
      if (_amount == "0") {
        if (val == ".") {
          _amount = "0.";
        } else {
          _amount = val;
        }
      } else {
        if (val == "." && _amount.contains(".")) {
          return;
        }
        _amount += val;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length <= 1) {
        _amount = "0";
      } else {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
  }

  void _sendMoney() async {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Số tiền chuyển không hợp lệ")),
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      double currentBalance = 5000.0;
      try {
        final doc = await userRef.get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          currentBalance = (doc.data()?['balance'] ?? 5000.0).toDouble();
        }
      } catch (_) {
        try {
          final doc = await userRef.get();
          if (doc.exists) {
            currentBalance = (doc.data()?['balance'] ?? 5000.0).toDouble();
          }
        } catch (_) {}
      }
      
      if (currentBalance < amount) {
        throw Exception("Số dư ví không đủ");
      }
      
      userRef.update({'balance': currentBalance - amount});
      
      final transRef = FirebaseFirestore.instance.collection('transactions').doc();
      transRef.set({
        'uid': user.uid,
        'type': 'transfer',
        'amount': amount,
        'description': 'Bank transfer to $_selectedRecipient',
        'timestamp': FieldValue.serverTimestamp(),
        'isIncome': false,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã gửi thành công \$${amount.toStringAsFixed(2)} tới $_selectedRecipient")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e("Send money error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Send Money", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, color: Colors.grey),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Wallet balance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text("Safe to spend", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            "\$${widget.currentBalance.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.orange,
                            radius: 20,
                            child: Text("a", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRecipient,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedRecipient = value;
                                    });
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(value: 'Amazon', child: Text("Amazon (New macbook air m2)")),
                                  DropdownMenuItem(value: 'Skyler', child: Text("Skyler")),
                                  DropdownMenuItem(value: 'Andrew', child: Text("Andrew")),
                                  DropdownMenuItem(value: 'Lavender', child: Text("Lavender")),
                                  DropdownMenuItem(value: 'Grace', child: Text("Grace")),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "\$$_amount",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 44, color: Color(0xFF7E3FF2)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "The transfer will be complete by Friday, August 21",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "back"];
                      final key = keys[index];
                      if (key == "back") {
                        return InkWell(
                          onTap: _onBackspace,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.backspace_outlined, size: 20),
                          ),
                        );
                      }
                      return InkWell(
                        onTap: () => _onKeyPress(key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              key,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _sendMoney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E3FF2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Send money", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
