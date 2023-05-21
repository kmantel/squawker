import 'package:flutter/material.dart';
import 'package:flutter_material_symbols/flutter_material_symbols.dart';
import 'package:flutter_triple/flutter_triple.dart';
import '../generated/l10n.dart';
import '../home/home_model.dart';
import '../ui/errors.dart';
import 'package:provider/provider.dart';

class SettingsHomeFragment extends StatelessWidget {
  const SettingsHomeFragment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var model = context.read<HomeModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.current.home),
        actions: [
          IconButton(
              icon: const Icon(MaterialSymbols.restart_alt),
              tooltip: L10n.current.reset_home_pages,
              onPressed: () async => await model.resetPages())
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ScopedBuilder<HomeModel, Object, List<HomePage>>.transition(
          store: model,
          onError: (_, e) => ScaffoldErrorWidget(
            prefix: L10n.current.unable_to_load_home_pages,
            error: e,
            stackTrace: null,
            onRetry: () async => await model.resetPages(),
            retryText: L10n.current.reset_home_pages,
          ),
          onLoading: (_) => const Center(child: CircularProgressIndicator()),
          onState: (_, data) {
            return ReorderableListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                var page = data[index];

                return CheckboxListTile(
                  key: Key(page.id),
                  secondary: const Icon(MaterialSymbols.drag_handle),
                  title: Text(page.page.titleBuilder(context)),
                  value: page.selected,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onChanged: (value) async {
                    var selected = value ?? false;
                    if (selected == false && data.where((e) => e.selected).length == 2) {
                      showSnackBar(context,
                          icon: '🙊', message: L10n.current.you_must_have_at_least_2_home_screen_pages);
                      return;
                    }

                    await model.selectPage(page.id, value ?? false);
                    await model.save();
                  },
                );
              },
              onReorder: (oldIndex, newIndex) async {
                await model.movePage(oldIndex, newIndex);
                await model.save();
              },
            );
          },
        ),
      ),
    );
  }
}
