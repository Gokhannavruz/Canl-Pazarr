import 'package:Freecycle/utils/colors2.dart';
import 'package:flutter/material.dart';

class PagePage extends StatefulWidget {
  const PagePage({Key? key}) : super(key: key);

  @override
  State<PagePage> createState() => _PagePageState();
}

class _PagePageState extends State<PagePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Subscription',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        body: Stack(
          children: [
            Container(
              width: 390,
              height: 844,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.black),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 57,
                    child: Container(
                      width: 390,
                      height: 422,
                      decoration: ShapeDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/unsplash.png'),
                          fit: BoxFit.fill,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 27,
                    top: 515,
                    child: Container(
                      width: 335,
                      height: 155,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 15,
                            child: Container(
                              width: 160,
                              height: 140,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Container(
                                      width: 160,
                                      height: 140,
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 17,
                                    top: 52,
                                    child: SizedBox(
                                      width: 125,
                                      height: 44.80,
                                      child: Text(
                                        '\$4.99/month',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF009FDE),
                                          fontSize: 30,
                                          fontFamily: 'PT Sans',
                                          fontWeight: FontWeight.w700,
                                          height: 0.03,
                                          letterSpacing: -0.60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 175,
                            top: 0,
                            child: Container(
                              width: 160,
                              height: 155,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 15,
                                    child: Container(
                                      width: 160,
                                      height: 140,
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 18,
                                    top: 61,
                                    child: SizedBox(
                                      width: 125,
                                      height: 48,
                                      child: Text(
                                        '\$49.99/year',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF009FDE),
                                          fontSize: 30,
                                          fontFamily: 'PT Sans',
                                          fontWeight: FontWeight.w700,
                                          height: 0.03,
                                          letterSpacing: -0.60,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    top: 120,
                                    child: SizedBox(
                                      width: 129,
                                      height: 30,
                                      child: Text(
                                        'only \$4.17/month',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontFamily: 'PT Sans',
                                          fontWeight: FontWeight.w400,
                                          height: 0.15,
                                          letterSpacing: -0.28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 32,
                                    top: 0,
                                    child: Container(
                                      width: 97,
                                      height: 29,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            child: Container(
                                              width: 97,
                                              height: 29,
                                              decoration: ShapeDecoration(
                                                color: Color(0xFFEDC994),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 10,
                                            top: 8,
                                            child: SizedBox(
                                              width: 77,
                                              height: 14,
                                              child: Text(
                                                'POPULAR',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontFamily: 'PT Sans',
                                                  fontWeight: FontWeight.w700,
                                                  height: 0.15,
                                                  letterSpacing: -0.28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 27,
                    top: 292,
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 194,
                            height: 24,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(children: []),
                                  ),
                                ),
                                Positioned(
                                  left: 35,
                                  top: 3,
                                  child: SizedBox(
                                    width: 159,
                                    height: 18,
                                    child: Text(
                                      'Ad-free listening',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: 'PT Sans',
                                        fontWeight: FontWeight.w400,
                                        height: 0.06,
                                        letterSpacing: -0.40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 347,
                            height: 24,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(children: []),
                                  ),
                                ),
                                Positioned(
                                  left: 35,
                                  top: 3,
                                  child: SizedBox(
                                    width: 312,
                                    height: 18,
                                    child: Text(
                                      'Curate unlimited playlists',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: 'PT Sans',
                                        fontWeight: FontWeight.w400,
                                        height: 0.06,
                                        letterSpacing: -0.40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 347,
                            height: 24,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(children: []),
                                  ),
                                ),
                                Positioned(
                                  left: 35,
                                  top: 3,
                                  child: SizedBox(
                                    width: 312,
                                    height: 18,
                                    child: Text(
                                      'Access over 150 stations',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: 'PT Sans',
                                        fontWeight: FontWeight.w400,
                                        height: 0.06,
                                        letterSpacing: -0.40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 347,
                            height: 24,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(children: []),
                                  ),
                                ),
                                Positioned(
                                  left: 35,
                                  top: 3,
                                  child: SizedBox(
                                    width: 312,
                                    height: 18,
                                    child: Text(
                                      'Stream in high-def',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: 'PT Sans',
                                        fontWeight: FontWeight.w400,
                                        height: 0.06,
                                        letterSpacing: -0.40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 347,
                            height: 24,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(children: []),
                                  ),
                                ),
                                Positioned(
                                  left: 35,
                                  top: 3,
                                  child: SizedBox(
                                    width: 312,
                                    height: 18,
                                    child: Text(
                                      'Invite up to 3 Family members',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: 'PT Sans',
                                        fontWeight: FontWeight.w400,
                                        height: 0.06,
                                        letterSpacing: -0.40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    top: 693,
                    child: Container(
                      width: 345,
                      height: 50,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 345,
                              height: 50,
                              decoration: ShapeDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(0.70, -0.71),
                                  end: Alignment(-0.7, 0.71),
                                  colors: [
                                    Color(0xFF67D6E0),
                                    Color(0xFF159FDE)
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 67.99,
                            top: 15,
                            child: SizedBox(
                              width: 209.03,
                              height: 19,
                              child: Text(
                                'Start Listening',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontFamily: 'PT Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 0.04,
                                  letterSpacing: -0.48,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 27,
                    top: 235,
                    child: SizedBox(
                      width: 331,
                      height: 43,
                      child: Text(
                        'Unlock Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w700,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 344,
                    top: 70,
                    child: Container(
                      width: 30,
                      height: 30,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Opacity(
                              opacity: 0.50,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: ShapeDecoration(
                                  color: Color(0xFFC4C4C4),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 4,
                            top: 8,
                            child: SizedBox(
                              width: 21,
                              height: 14,
                              child: Text(
                                'X',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFC4C4C4),
                                  fontSize: 16,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 0.09,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 23,
                    top: 756,
                    child: Container(
                      width: 340,
                      height: 40,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: SizedBox(
                              width: 115,
                              height: 40,
                              child: Text(
                                'Restore Purchases',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'PT Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 0.12,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 149,
                            top: 0,
                            child: SizedBox(
                              width: 77,
                              height: 40,
                              child: Text(
                                'Terms of Use',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'PT Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 0.12,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 261,
                            top: 0,
                            child: SizedBox(
                              width: 79,
                              height: 40,
                              child: Text(
                                'Privacy Policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'PT Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 0.12,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 27,
                    top: 492,
                    child: SizedBox(
                      width: 149,
                      height: 38,
                      child: Text(
                        'Pick your plan:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'PT Sans',
                          fontWeight: FontWeight.w700,
                          height: 0.07,
                          letterSpacing: -0.36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    const SizedBox(
                      height: 20,
                    ),

                    // Display monthly subscription UI
                    const SizedBox(
                      height: 20,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    // _buildYearlySubTile(), // Display yearly subscription UI
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMonthlySubscriptionTile() {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14), color: Colors.blue.shade900),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductTitle("Monthly Subscription"),
                  const SizedBox(height: 5),
                  _buildProductPrice("\$9.99"),
                  const SizedBox(height: 5),
                  _buildPriceChangeButton(),
                ],
              ),
              const Expanded(child: SizedBox(width: 3)),
            ],
          ),
          const Divider(),
          _buildSubscriptionBenefits(),
          const SizedBox(height: 20),
          _buildSubscriptionButton(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProductTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.white,
        fontSize: 18,
      ),
    );
  }

  Widget _buildProductPrice(String price) {
    return Text(
      price,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPriceChangeButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: AppColors.c2,
        ),
        alignment: Alignment.center,
        child: const Text(
          'Price Change',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBenefits() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubscriptionBenefitTitle(
              'Only \$9.99 per month',
            ),
            // more professional UI
            const SizedBox(height: 10),
            _buildSubscriptionBenefit(
              'Unlimited access to all features',
              'Post unlimited items',
            ),
            const SizedBox(height: 10),
            _buildSubscriptionBenefit(
              'Unlimited access to all features',
              'Post unlimited items',
            ),
            const SizedBox(height: 10),
            _buildSubscriptionBenefit(
              'Unlimited access to all features',
              'Post unlimited items',
            ),
            const SizedBox(height: 10),
            _buildSubscriptionBenefit(
              'Unlimited access to all features',
              'Post unlimited items',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionBenefitTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildSubscriptionBenefit(String subtitle, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          overflow: TextOverflow.visible,
        ),
        Text(
          '   - $description',
          style: const TextStyle(fontSize: 14, color: Colors.black),
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  Widget _buildSubscriptionWarning(String warning, {Color? color}) {
    return Column(
      children: [
        const Icon(
          Icons.info,
          color: Colors.blue,
        ),
        Text(
          warning,
          style: TextStyle(fontSize: 12, color: color),
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  Widget _buildSubscriptionButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.c2,
        ),
        alignment: Alignment.center,
        child: Text(
          'Choose Plan',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

_buildYearlySubTile() {
  // Your code for displaying Yearly Subscription UI
}
