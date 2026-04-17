import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../providers/app_settings_provider.dart';
import '../providers/customization_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/analytics_service.dart';
import '../theme_colors.dart';
import '../theme_provider.dart';
import '../widgets/remove_ads_dialog.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'appearance_screen');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeState = ref.watch(themeProviderNotifierProvider);
    final themeNotifier = ref.read(themeProviderNotifierProvider.notifier);
    final isFounder = ref.watch(isFounderProvider);
    final isMaterialYouAvailable =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android);
    final founderColor = AquaThemeColors.founderColor(context);

    return MainLayout(
      title: l10n.appearance,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.appearance,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appearanceSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ── Light / Dark / System ──────────────────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    context,
                    Icons.brightness_6_outlined,
                    l10n.brightnessMode,
                    cs.primary,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(l10n.light),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_outlined),
                          label: Text(l10n.system),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(l10n.dark),
                        ),
                      ],
                      selected: {themeState.themeMode},
                      onSelectionChanged: (modes) {
                        AnalyticsService.logSettingsChange(
                          settingName: 'theme_mode',
                          newValue: modes.first.name,
                          oldValue: themeState.themeMode.name,
                        );
                        themeNotifier.setThemeMode(modes.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Colour Themes ──────────────────────────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    context,
                    Icons.palette_outlined,
                    l10n.colourTheme,
                    cs.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.chooseColourPalette,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  _ThemeGrid(
                    selected: themeState.colorTheme,
                    isMaterialYouAvailable: isMaterialYouAvailable,
                    customSeedColor: themeState.customSeedColor,
                    customThemeName: themeState.customThemeName,
                    onSelected: (theme) {
                      AnalyticsService.logSettingsChange(
                        settingName: 'color_theme',
                        newValue: theme.name,
                        oldValue: themeState.colorTheme.name,
                      );
                      themeNotifier.setColorTheme(theme);
                    },
                    onCustomEdit: () => _showCustomThemePicker(
                      context,
                      themeState.customSeedColor,
                      themeState.customThemeName,
                      themeNotifier,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Font Selection ─────────────────────────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    context,
                    Icons.font_download_outlined,
                    l10n.font,
                    cs.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.chooseFontDesc,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  _FontSelector(
                    selected: themeState.font,
                    onSelected: (font) {
                      AnalyticsService.logSettingsChange(
                        settingName: 'app_font',
                        newValue: font.name,
                        oldValue: themeState.font.name,
                      );
                      themeNotifier.setFont(font);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Layout Customization (Founder only) ────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    context,
                    Icons.dashboard_customize,
                    l10n.layoutCustomization,
                    isFounder ? founderColor : cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.layoutCustomizationDesc,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),

                  // Customize Welcome Cards
                  Opacity(
                    opacity: isFounder ? 1.0 : 0.5,
                    child: ListTile(
                      leading: Icon(
                        Icons.dashboard_customize,
                        color: isFounder ? founderColor : cs.onSurfaceVariant,
                      ),
                      title: Text(l10n.customizeWelcomeCards),
                      subtitle: Text(l10n.customizeWelcomeCardsDesc),
                      trailing: isFounder
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : Tooltip(
                              message: l10n.founderRequiredTooltip,
                              child: Icon(
                                Icons.lock,
                                size: 16,
                                color: founderColor,
                              ),
                            ),
                      onTap: isFounder
                          ? () => _showWelcomeCardReorderDialog()
                          : kIsWeb
                              ? null
                              : () => showRemoveAdsDialog(context),
                    ),
                  ),
                  const Divider(height: 1),

                  // Customize Sidebar
                  Opacity(
                    opacity: isFounder ? 1.0 : 0.5,
                    child: ListTile(
                      leading: Icon(
                        Icons.menu_open,
                        color: isFounder ? founderColor : cs.onSurfaceVariant,
                      ),
                      title: Text(l10n.customizeSidebar),
                      subtitle: Text(l10n.customizeSidebarDesc),
                      trailing: isFounder
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : Tooltip(
                              message: l10n.founderRequiredTooltip,
                              child: Icon(
                                Icons.lock,
                                size: 16,
                                color: founderColor,
                              ),
                            ),
                      onTap: isFounder
                          ? () => _showSidebarReorderDialog()
                          : kIsWeb
                              ? null
                              : () => showRemoveAdsDialog(context),
                    ),
                  ),

                  if (!isFounder) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.founderFeatureLocked,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: founderColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reorder Dialogs ──────────────────────────────────────────────────

  void _showWelcomeCardReorderDialog() {
    final l10n = AppLocalizations.of(context)!;
    final appSettings = ref.read(appSettingsProvider);
    final founderColor = AquaThemeColors.founderColor(context);

    // Build the default feature list (same IDs as welcome screen)
    final defaultIds = <String>[
      if (appSettings.enableAI) ...[
        '/compat-ai',
        '/chatbot',
        '/chatbot_photo', // photo analyzer
        '/stocking',
      ],
      '/calculators',
      '/tank-volume',
      '/substrate',
      '/dosing-calculator',
      '/compat-browser',
      '/community',
      'aquapi_store',
    ];

    // Map IDs to display names
    final idToName = <String, String>{
      '/compat-ai': l10n.aiCompatibilityTool,
      '/chatbot': l10n.aiChatbot,
      '/chatbot_photo': l10n.photoAnalyzer,
      '/stocking': l10n.aiStockingAssistant,
      '/calculators': l10n.aquariumCalculators,
      '/tank-volume': l10n.tankVolumeCalculator,
      '/substrate': l10n.substrateCalculator,
      '/dosing-calculator': l10n.dosingCalculator,
      '/compat-browser': l10n.fishCompatBrowser,
      '/community': l10n.communityTitle,
      'aquapi_store': l10n.aquaPiStore,
    };

    // Get current order from provider
    final customization = ref.read(customizationProvider);
    final currentOrder = customization.welcomeCardOrder;

    // Build working list
    List<String> workingOrder = applyCustomOrder(defaultIds, currentOrder);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(ctx).size.width,
            height: MediaQuery.of(ctx).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: founderColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard_customize,
                        color: founderColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.welcomeCards,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                        tooltip: l10n.close,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    l10n.dragToReorder,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: workingOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = workingOrder.removeAt(oldIndex);
                        workingOrder.insert(newIndex, item);
                      });
                      ref
                          .read(customizationProvider.notifier)
                          .setWelcomeCardOrder(workingOrder);
                    },
                    itemBuilder: (ctx, index) {
                      final id = workingOrder[index];
                      return ListTile(
                        key: ValueKey(id),
                        leading: Icon(
                          Icons.drag_handle,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(idToName[id] ?? id),
                        trailing: Text(
                          '${index + 1}',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: () {
                      ref
                          .read(customizationProvider.notifier)
                          .resetWelcomeCardOrder();
                      setDialogState(() {
                        workingOrder
                          ..clear()
                          ..addAll(defaultIds);
                      });
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.orderReset)),
                        );
                      }
                    },
                    icon: const Icon(Icons.restore, size: 18),
                    label: Text(l10n.resetToDefault),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSidebarReorderDialog() {
    final l10n = AppLocalizations.of(context)!;
    final appSettings = ref.read(appSettingsProvider);
    final founderColor = AquaThemeColors.founderColor(context);

    // Build the default list of sidebar items, respecting AI toggle
    final defaultIds = <String>[
      if (appSettings.enableAI) ...[
        'compat-ai',
        'chatbot',
        'stocking',
        'analysis-history',
      ],
      'calculators',
      'tank-volume',
      'substrate',
      'dosing-calculator',
      'compat-browser',
      'notifications',
      'community',
      'profile',
      'information',
    ];

    // Map IDs to display names
    final idToName = <String, String>{
      'compat-ai': l10n.aiCompatibilityTool,
      'chatbot': l10n.aiChatbot,
      'stocking': l10n.aiStockingAssistant,
      'analysis-history': l10n.analysisHistory,
      'calculators': l10n.aquariumCalculators,
      'tank-volume': l10n.tankVolumeCalculator,
      'substrate': l10n.substrateCalculator,
      'dosing-calculator': l10n.dosingCalculator,
      'compat-browser': l10n.fishCompatBrowser,
      'notifications': l10n.allNotifications,
      'community': l10n.communityTitle,
      'profile': l10n.profileTitle,
      'information': l10n.information,
    };

    // Get current state
    final customization = ref.read(customizationProvider);
    final currentOrder = customization.sidebarOrder;
    final hiddenItems = Set<String>.from(customization.hiddenSidebarItems);

    // Build working list
    List<String> workingOrder = applyCustomOrder(defaultIds, currentOrder);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(ctx).size.width,
            height: MediaQuery.of(ctx).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: founderColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_open, color: founderColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.sidebarMenuItems,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                        tooltip: l10n.close,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    l10n.dragToReorder,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: workingOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = workingOrder.removeAt(oldIndex);
                        workingOrder.insert(newIndex, item);
                      });
                      ref
                          .read(customizationProvider.notifier)
                          .setSidebarOrder(workingOrder);
                    },
                    itemBuilder: (ctx, index) {
                      final id = workingOrder[index];
                      final isHidden = hiddenItems.contains(id);
                      return CheckboxListTile(
                        key: ValueKey(id),
                        value: !isHidden,
                        title: Text(idToName[id] ?? id),
                        secondary: Icon(
                          Icons.drag_handle,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              hiddenItems.remove(id);
                            } else {
                              hiddenItems.add(id);
                            }
                          });
                          ref
                              .read(customizationProvider.notifier)
                              .setHiddenSidebarItems(hiddenItems);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: () {
                      ref
                          .read(customizationProvider.notifier)
                          .resetSidebarOrder();
                      setDialogState(() {
                        workingOrder
                          ..clear()
                          ..addAll(defaultIds);
                        hiddenItems.clear();
                      });
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.orderReset)),
                        );
                      }
                    },
                    icon: const Icon(Icons.restore, size: 18),
                    label: Text(l10n.resetToDefault),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the custom colour picker dialog.
  void _showCustomThemePicker(
    BuildContext context,
    Color initialColor,
    String initialName,
    ThemeProviderNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _CustomThemeDialog(
        initialColor: initialColor,
        initialName: initialName,
        onSave: (color, name) => notifier.setCustomTheme(color, name),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Font selector
// ---------------------------------------------------------------------------

class _FontSelector extends StatelessWidget {
  const _FontSelector({required this.selected, required this.onSelected});

  final AppFont selected;
  final ValueChanged<AppFont> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: AppFont.values.map((font) {
        final isSelected = selected == font;
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? cs.primaryContainer.withOpacity(0.3)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          font.displayName,
                          style: TextStyle(
                            fontFamily: font.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.fontPreviewText,
                          style: TextStyle(
                            fontFamily: font.fontFamily,
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: cs.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme grid
// ---------------------------------------------------------------------------

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.selected,
    required this.isMaterialYouAvailable,
    required this.customSeedColor,
    required this.customThemeName,
    required this.onSelected,
    required this.onCustomEdit,
  });

  final AppColorTheme selected;
  final bool isMaterialYouAvailable;
  final Color customSeedColor;
  final String customThemeName;
  final ValueChanged<AppColorTheme> onSelected;
  final VoidCallback onCustomEdit;

  @override
  Widget build(BuildContext context) {
    final themes = AppColorTheme.values
        .where((t) => t != AppColorTheme.materialYou || isMaterialYouAvailable)
        .toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: themes
          .map(
            (t) => _ThemeChip(
              theme: t,
              isSelected: selected == t,
              customSeedColor: customSeedColor,
              customThemeName: customThemeName,
              // Custom chip: open the picker; setCustomTheme handles selection.
              // Other chips: directly select the theme.
              onTap: t == AppColorTheme.custom
                  ? onCustomEdit
                  : () => onSelected(t),
              onCustomEdit: t == AppColorTheme.custom ? onCustomEdit : null,
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: returns the localized display name for a colour theme.
// ---------------------------------------------------------------------------

String _themeLocalizedName(AppColorTheme theme, AppLocalizations l10n) {
  switch (theme) {
    case AppColorTheme.defaultTheme:
      return l10n.themeDefault;
    case AppColorTheme.materialYou:
      return l10n.themeMaterialYou;
    case AppColorTheme.oceanBlue:
      return l10n.themeOceanBlue;
    case AppColorTheme.iceBlue:
      return l10n.themeIceBlue;
    case AppColorTheme.gold:
      return l10n.themeGold;
    case AppColorTheme.mulberry:
      return l10n.themeMulberry;
    case AppColorTheme.midnight:
      return l10n.themeMidnight;
    case AppColorTheme.orange:
      return l10n.themeOrange;
    case AppColorTheme.green:
      return l10n.themeGreen;
    case AppColorTheme.skyBlue:
      return l10n.themeSkyBlue;
    case AppColorTheme.royalBlue:
      return l10n.themeRoyalBlue;
    case AppColorTheme.orchid:
      return l10n.themeOrchid;
    case AppColorTheme.hotPink:
      return l10n.themeHotPink;
    case AppColorTheme.crimson:
      return l10n.themeCrimson;
    case AppColorTheme.custom:
      return l10n.colorCustom;
  }
}

// ---------------------------------------------------------------------------
// Individual theme chip
// ---------------------------------------------------------------------------

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.isSelected,
    required this.customSeedColor,
    required this.customThemeName,
    required this.onTap,
    this.onCustomEdit,
  });

  final AppColorTheme theme;
  final bool isSelected;
  final Color customSeedColor;
  final String customThemeName;
  final VoidCallback onTap;
  final VoidCallback? onCustomEdit;

  static const _swatchPrimary = {
    AppColorTheme.defaultTheme: AquaThemeColors.defaultSwatchPrimary,
    AppColorTheme.materialYou: Colors.deepPurple,
    AppColorTheme.oceanBlue: AquaThemeColors.oceanBlueSwatchPrimary,
    AppColorTheme.iceBlue: AquaThemeColors.iceBlueSwatchPrimary,
    AppColorTheme.gold: AquaThemeColors.goldSwatchPrimary,
    AppColorTheme.mulberry: AquaThemeColors.mulberrySwatchPrimary,
    AppColorTheme.midnight: AquaThemeColors.midnightSwatchPrimary,
    AppColorTheme.orange: AquaThemeColors.orangeSwatchPrimary,
    AppColorTheme.green: AquaThemeColors.greenSwatchPrimary,
    AppColorTheme.skyBlue: AquaThemeColors.skyBlueSwatchPrimary,
    AppColorTheme.royalBlue: AquaThemeColors.royalBlueSwatchPrimary,
    AppColorTheme.orchid: AquaThemeColors.orchidSwatchPrimary,
    AppColorTheme.hotPink: AquaThemeColors.hotPinkSwatchPrimary,
    AppColorTheme.crimson: AquaThemeColors.crimsonSwatchPrimary,
  };

  static const _swatchSecondary = {
    AppColorTheme.defaultTheme: AquaThemeColors.defaultSwatchSecondary,
    AppColorTheme.materialYou: Colors.purple,
    AppColorTheme.oceanBlue: AquaThemeColors.oceanBlueSwatchSecondary,
    AppColorTheme.iceBlue: AquaThemeColors.iceBlueSwatchSecondary,
    AppColorTheme.gold: AquaThemeColors.goldSwatchSecondary,
    AppColorTheme.mulberry: AquaThemeColors.mulberrySwatchSecondary,
    AppColorTheme.midnight: AquaThemeColors.midnightSwatchSecondary,
    AppColorTheme.orange: AquaThemeColors.orangeSwatchSecondary,
    AppColorTheme.green: AquaThemeColors.greenSwatchSecondary,
    AppColorTheme.skyBlue: AquaThemeColors.skyBlueSwatchSecondary,
    AppColorTheme.royalBlue: AquaThemeColors.royalBlueSwatchSecondary,
    AppColorTheme.orchid: AquaThemeColors.orchidSwatchSecondary,
    AppColorTheme.hotPink: AquaThemeColors.hotPinkSwatchSecondary,
    AppColorTheme.crimson: AquaThemeColors.crimsonSwatchSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final isCustom = theme == AppColorTheme.custom;

    // Swatch colours: custom theme uses the user-defined seed colour.
    final Color primary = isCustom
        ? customSeedColor
        : (_swatchPrimary[theme] ?? Colors.grey);
    final Color secondary;
    if (isCustom) {
      final hsl = HSLColor.fromColor(customSeedColor);
      secondary = hsl
          .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
          .toColor();
    } else {
      secondary = _swatchSecondary[theme] ?? Colors.grey.shade700;
    }

    final String label = isCustom
        ? customThemeName
        : _themeLocalizedName(theme, AppLocalizations.of(context)!);

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (theme == AppColorTheme.materialYou)
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            // Custom theme always shows an edit/add icon
            if (isCustom)
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: onCustomEdit,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: cs.onPrimary, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom theme picker dialog
// ---------------------------------------------------------------------------

class _CustomThemeDialog extends StatefulWidget {
  const _CustomThemeDialog({
    required this.initialColor,
    required this.initialName,
    required this.onSave,
  });

  final Color initialColor;
  final String initialName;
  final void Function(Color color, String name) onSave;

  @override
  State<_CustomThemeDialog> createState() => _CustomThemeDialogState();
}

class _CustomThemeDialogState extends State<_CustomThemeDialog> {
  late Color _pickedColor;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _pickedColor = widget.initialColor;
    _nameController = TextEditingController(
      text: widget.initialName == kDefaultCustomThemeName
          ? ''
          : widget.initialName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.customTheme),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              pickerColor: _pickedColor,
              onColorChanged: (c) => setState(() => _pickedColor = c),
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.7,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.themeName,
                hintText: kDefaultCustomThemeName,
                border: const OutlineInputBorder(),
              ),
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_pickedColor, _nameController.text);
            Navigator.of(context).pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
