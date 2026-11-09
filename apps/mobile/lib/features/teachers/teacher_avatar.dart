import 'package:flutter/material.dart';

import '../../shared/ui/ui.dart';
import '../../shared/widgets/network_avatar.dart';

/// A teacher's photo inside a pink ring (the teachers colour, spec §2). Decorative: the name next
/// to it is what screen readers read.
class TeacherAvatar extends StatelessWidget {
  const TeacherAvatar({super.key, required this.url, required this.name, this.radius = 24});

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: EdgeInsets.all(radius > 30 ? 4 : 2.5),
      decoration: BoxDecoration(color: PlengoColors.pink.base, shape: BoxShape.circle),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: context.surface.card, shape: BoxShape.circle),
        child: NetworkAvatar(url: url, name: name, radius: radius),
      ),
    ),
  );
}
