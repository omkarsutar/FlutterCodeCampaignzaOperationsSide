import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const CustomAppBar({
    required this.title,
    this.showBack = true,
    this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            )
          : null, // ✅ Let Flutter show drawer icon if showBack is false
      title: Text(title),
      automaticallyImplyLeading:
          !showBack, // ✅ Enable drawer icon when back is off
      actions: [
        ...?actions, // ✅ allows additional actions from the page
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
