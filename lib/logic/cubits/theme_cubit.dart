import 'package:bookcart/core/theme/app_color_palette.dart';
import 'package:bookcart/data/repository/app_preferences_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<AppColorPalette> {
  ThemeCubit(this._preferencesRepository) : super(AppThemePalettes.forest) {
    _loadPersistedPalette();
  }

  final AppPreferencesRepository _preferencesRepository;

  Future<void> _loadPersistedPalette() async {
    final paletteId = await _preferencesRepository.readThemePaletteId();
    final palette = AppThemePalettes.byId(paletteId);
    if (state.id != palette.id) {
      emit(palette);
    }
  }

  void selectPalette(AppColorPalette palette) {
    if (state.id == palette.id) {
      return;
    }

    emit(palette);
    _preferencesRepository.writeThemePaletteId(palette.id);
  }
}
