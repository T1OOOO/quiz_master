# Local MapLibre patch

These directories are copies of `maplibre_gl` and `maplibre_gl_web` 0.27.1 from pub.dev, under their included BSD 3-Clause licenses. Keep the LICENSE files when redistributing.

The `disableSymbolPlacementFade` constructor option defaults to false and is enabled only by the knowledge map. It is forwarded as a platform-view creation parameter. Web sets MapLibre GL JS `MapOptions.fadeDuration` to zero; Android applies `Style.setTransition(TransitionOptions(duration, delay, false))`, preserving the current style duration and delay whenever the style loads. iOS does not implement this option. The change is experimental: verify visual transitions and tap behavior on each target before release.

Changed upstream files: `maplibre_gl/lib/src/maplibre_map.dart`, Android `MapLibreMapBuilder.java`, `MapLibreMapController.java`, `MapLibreMapFactory.java`, and `maplibre_gl_web/lib/src/maplibre_web_gl_platform.dart`. The package analysis options also point to this application's lint settings. On upgrading, reapply and review these changes against the new release.

For the opt-in map, Android reports source update failures and web reports missing or non-GeoJSON sources instead of silently succeeding. The application commits its thematic mode only after the platform update returns successfully. Android accepts source updates asynchronously, so success does not prove the new tiles have rendered.
