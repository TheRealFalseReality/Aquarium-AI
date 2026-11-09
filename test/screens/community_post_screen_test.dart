import 'package:firebase_auth/firebase_auth.dart';
import 'package:fish_ai/l10n/app_localizations.dart';
import 'package:fish_ai/models/community_comment.dart';
import 'package:fish_ai/models/community_post.dart';
import 'package:fish_ai/providers/community_provider.dart';
import 'package:fish_ai/screens/community_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final samplePost = CommunityPost(
    id: 'post-1',
    userId: 'user-1',
    displayName: 'Aquarist',
    type: PostType.question,
    title: 'Question title',
    body: 'Question body',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        communityCommentsStreamProvider(samplePost.id).overrideWith(
          (ref) => Stream<List<CommunityComment>>.value(const []),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CommunityPostScreen(post: samplePost),
      ),
    );
  }

  testWidgets('comment composer supports multiline growth', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.keyboardType, TextInputType.multiline);
    expect(textField.textInputAction, TextInputAction.newline);
    expect(textField.minLines, 1);
    expect(textField.maxLines, 6);
  });
}
