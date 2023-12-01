import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final GestureTapCallback? onTap;
  final String buttonLabel;
  final Color? color;

  const CommonButton(
      {Key? key, this.onTap, required this.buttonLabel, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        alignment: Alignment.center,
        height: 50,
        width: 200,
        decoration: BoxDecoration(
            color: color ?? Colors.blue,
            borderRadius: BorderRadius.circular(30)),
        child: Text(
          buttonLabel,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
