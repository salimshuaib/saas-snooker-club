import re

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_body = '''      body: tablesAsync.when(
        data: (tables) {
          if (tables.isEmpty) {
            return const Center(child: Text('No tables configured.', style: TextStyle(color: AppColors.previewLightBackground)));
          }

          final snookerTables = tables.where((t) => t.type == TableType.snooker).toList();
          final poolTables = tables.where((t) => t.type == TableType.indianPool || t.type == TableType.americanPool).toList();
          final consoleTables = tables.where((t) => t.type == TableType.ps5 || t.type == TableType.ps4 || t.type == TableType.pc || t.type == TableType.arcade).toList();
          
          final existingTypes = <String>[];
          if (snookerTables.isNotEmpty) existingTypes.add('Snooker');
          if (poolTables.isNotEmpty) existingTypes.add('Pool');
          if (consoleTables.isNotEmpty) existingTypes.add('Console & PC');
          
          final otherTables = tables.where((t) => !snookerTables.contains(t) && !poolTables.contains(t) && !consoleTables.contains(t)).toList();
          if (otherTables.isNotEmpty) existingTypes.add('Other');

          return DefaultTabController(
            length: existingTypes.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: AppColors.previewSecondary,
                  labelColor: AppColors.previewSecondary,
                  unselectedLabelColor: AppColors.previewLightBackground.withValues(alpha: 0.5),
                  dividerColor: AppColors.previewLine,
                  tabs: existingTypes.map((t) => Tab(text: t)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: existingTypes.map((type) {
                      List<TableModel> tabTables = [];
                      if (type == 'Snooker') tabTables = snookerTables;
                      else if (type == 'Pool') tabTables = poolTables;
                      else if (type == 'Console & PC') tabTables = consoleTables;
                      else if (type == 'Other') tabTables = otherTables;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                        itemCount: tabTables.length,
                        itemBuilder: (context, index) {
                          return GameActivityCard(table: tabTables[index]);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: \', style: const TextStyle(color: AppColors.previewLightBackground))),
      ),'''

new_body = '''      body: Builder(
        builder: (context) {
          final tables = tablesAsync;
          if (tables.isEmpty) {
            return const Center(child: Text('No tables configured.', style: TextStyle(color: AppColors.previewLightBackground)));
          }

          final snookerTables = tables.where((t) => t.type == TableType.snooker).toList();
          final poolTables = tables.where((t) => t.type == TableType.indianPool || t.type == TableType.americanPool).toList();
          final consoleTables = tables.where((t) => t.type == TableType.ps5 || t.type == TableType.ps4 || t.type == TableType.pc || t.type == TableType.arcade).toList();
          
          final existingTypes = <String>[];
          if (snookerTables.isNotEmpty) existingTypes.add('Snooker');
          if (poolTables.isNotEmpty) existingTypes.add('Pool');
          if (consoleTables.isNotEmpty) existingTypes.add('Console & PC');
          
          final otherTables = tables.where((t) => !snookerTables.contains(t) && !poolTables.contains(t) && !consoleTables.contains(t)).toList();
          if (otherTables.isNotEmpty) existingTypes.add('Other');

          return DefaultTabController(
            length: existingTypes.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: AppColors.previewSecondary,
                  labelColor: AppColors.previewSecondary,
                  unselectedLabelColor: AppColors.previewLightBackground.withValues(alpha: 0.5),
                  dividerColor: AppColors.previewLine,
                  tabs: existingTypes.map((t) => Tab(text: t)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: existingTypes.map((type) {
                      List<TableModel> tabTables = [];
                      if (type == 'Snooker') tabTables = snookerTables;
                      else if (type == 'Pool') tabTables = poolTables;
                      else if (type == 'Console & PC') tabTables = consoleTables;
                      else if (type == 'Other') tabTables = otherTables;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                        itemCount: tabTables.length,
                        itemBuilder: (context, index) {
                          return GameActivityCard(table: tabTables[index]);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),'''
text = text.replace(old_body, new_body)

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
