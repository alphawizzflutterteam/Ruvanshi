import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Color.dart';

class AppBtn extends StatelessWidget {
  final String? title;
  final AnimationController? btnCntrl;
  final Animation? btnAnim;
  final VoidCallback? onBtnSelected;

  const AppBtn(
      {Key? key, this.title, this.btnCntrl, this.btnAnim, this.onBtnSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      builder: _buildBtnAnimation,
      animation: btnCntrl!,
    );
  }

  Widget _buildBtnAnimation(BuildContext context, Widget? child) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: CupertinoButton(
        child: Container(
          width: 500,
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          ),
          child: btnAnim!.value > 75.0
              ? Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: colors.whiteTemp,
                      fontWeight: FontWeight.normal,
                      fontFamily: dynamicFontFamily.fontFamily),
                )
              : const CircularProgressIndicator(),
        ),
        onPressed: () {
          onBtnSelected!();
        },
      ),
    );
  }
}
