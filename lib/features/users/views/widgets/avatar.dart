import 'dart:io';

import 'package:geo_economy_dashboard/features/users/view_models/avatar_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class Avatar extends ConsumerWidget {
  final String name;
  final bool hasAvatar;
  final String uid;
  const Avatar({
    required this.name,
    required this.hasAvatar,
    required this.uid,
    super.key,
  });

  Future<void> _onAvatarTap(BuildContext context, WidgetRef ref) async {
    final XFile? xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxHeight: 150,
      maxWidth: 150,
    );
    if (xfile != null && context.mounted) {
      final file = File(xfile.path);
      ref.read(avatarProvider.notifier).uploadAvatar(context, file);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(avatarProvider).isLoading;
    return GestureDetector(
      onTap: isLoading ? null : () => _onAvatarTap(context, ref),
      child: isLoading
          ? Container(
              alignment: Alignment.center,
              width: 50,
              height: 50,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const CircularProgressIndicator(),
            )
          : CircleAvatar(
              radius: 50,
              foregroundImage: hasAvatar
                  ? NetworkImage(
                      "https://firebasestorage.googleapis.com/v0/b/ecodataatlas.firebasestorage.app/o/avatars%2F$uid?alt=media&haha=${DateTime.now().toString()}",
                    )
                  : null,
              child: Text(name),
            ),
    );
  }
}
