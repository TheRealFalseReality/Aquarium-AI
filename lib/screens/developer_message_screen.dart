import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';

class DeveloperMessageScreen extends ConsumerStatefulWidget {
  const DeveloperMessageScreen({super.key});

  @override
  ConsumerState<DeveloperMessageScreen> createState() =>
      _DeveloperMessageScreenState();
}

class _DeveloperMessageScreenState extends ConsumerState<DeveloperMessageScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'developer_message_screen');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messageId = RemoteConfigService.serverMessageId;
    final title = RemoteConfigService.serverMessageTitle;
    final message = RemoteConfigService.serverMessage;
    final hasMessage = messageId.trim().isNotEmpty && message.trim().isNotEmpty;
    final displayTitle = title.isNotEmpty ? title : l10n.serverMessageDefaultTitle;

    return MainLayout(
      title: l10n.developerMessage,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: hasMessage
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: Text(
                  l10n.serverMessageNoCurrentMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}
