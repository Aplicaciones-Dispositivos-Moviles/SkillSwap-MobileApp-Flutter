part of 'share_bloc.dart';

sealed class ShareEvent {
  const ShareEvent();
}

// Abre la pantalla: habilidades verificadas, rango y enlaces ya generados.
class ShareRequested extends ShareEvent {
  const ShareRequested();
}

// El Verificador elige la habilidad a destacar: se genera (o reutiliza) su enlace público.
class ShareSkillSelected extends ShareEvent {
  final String skillTag;

  const ShareSkillSelected(this.skillTag);
}
