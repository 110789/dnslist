import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../state/theme_provider.dart';
import '../../services/services.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? leading;
  final bool showBackButton;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.leading,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

    if (isCupertino) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          leading: showBackButton
              ? CupertinoNavigationBarBackButton(
                  onPressed: () => Navigator.maybePop(context),
                )
              : (leading as Widget?),
          trailing: actions != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                )
              : null,
        ),
        child: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        leading: showBackButton
            ? null
            : leading ?? (drawer != null ? null : const SizedBox.shrink()),
        actions: actions,
      ),
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;
  final IconData? icon;

  const AdaptiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

    if (isCupertino) {
      return CupertinoButton(
        onPressed: isLoading ? null : onPressed,
        color: isDestructive ? CupertinoColors.destructiveRed : null,
        child: isLoading
            ? const CupertinoActivityIndicator()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 4),
                  ],
                  Text(label),
                ],
              ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: isDestructive
          ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
          : null,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(label),
              ],
            ),
    );
  }
}

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AdaptiveTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

    if (isCupertino) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            placeholder: hint,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
              border: errorText != null
                  ? Border.all(color: CupertinoColors.destructiveRed)
                  : null,
            ),
            onChanged: onChanged,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ],
        ],
      );
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

class AdaptiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const AdaptiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

    if (isCupertino) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: content,
        actions: actions ??
            [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
      );
    }

    return AlertDialog(
      title: Text(title),
      content: content,
      actions: actions,
    );
  }
}

Future<bool?> showAdaptiveDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  bool isDestructive = false,
}) async {
  final themeProvider = context.read<ThemeProvider>();
  final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

  if (isCupertino) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: isDestructive ? TextButton.styleFrom(foregroundColor: Colors.red) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

class AdaptiveListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdaptiveListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

    if (isCupertino) {
      return CupertinoListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        leading: leading,
        trailing: trailing ?? const CupertinoListTileChevron(),
        onTap: onTap,
      );
    }

    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

    if (isCupertino) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (label != null) Text(label!),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      );
    }

    return SwitchListTile(
      title: label != null ? Text(label!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class AdaptiveSegmentedControl<T> extends StatelessWidget {
  final Map<T, Widget> children;
  final T selectedValue;
  final ValueChanged<T>? onValueChanged;

  const AdaptiveSegmentedControl({
    super.key,
    required this.children,
    required this.selectedValue,
    this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isCupertino = themeProvider.uiStyle == UIStyle.cupertino;

    if (isCupertino) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: selectedValue,
        children: children,
        onValueChanged: (value) {
          if (value != null) onValueChanged?.call(value);
        },
      );
    }

    return SegmentedButton<T>(
      segments: children.entries.map((e) => ButtonSegment(
        value: e.key,
        label: e.value as Widget,
      )).toList(),
      selected: {selectedValue},
      onSelectionChanged: (selection) {
        onValueChanged?.call(selection.first);
      },
    );
  }
}

class AdaptiveEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const AdaptiveEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final color = isDark ? Colors.white54 : Colors.black45;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: TextStyle(fontSize: 14, color: color),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 32),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class AdaptiveLoading extends StatelessWidget {
  final String? message;

  const AdaptiveLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}