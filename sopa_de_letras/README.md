# Sopa de Letras 🔍🔤 — Classic Word Search Puzzle Game

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Audio](https://img.shields.io/badge/Audio-BGM%20%26%20SFX-blue)]()
[![Author](https://img.shields.io/badge/Studio-Inventus%20Tech-orange)]()

> **Sopa de Letras** es un videojuego clásico de búsqueda de palabras desarrollado en Flutter (+6,200 líneas de código). Incorpora un motor de dibujo matricial con detección de trazos táctiles en cualquier dirección (horizontal, vertical, diagonal e invertida), acompañamiento musical interactivo, sistema de pistas y monetización no intrusiva.

---

## 🌟 Características Principales

* **Motor Matricial de Selección Táctil:**
  * Algoritmo de detección de arrastre táctil continuo sobre la cuadrícula.
  * Trazado de líneas de colores personalizadas sobre las palabras encontradas.
* **Progresión de Niveles & Temáticas Dinámicas:**
  * Decenas de niveles configurables (`LevelConfig`) con palabras temáticas (naturaleza, ciencia, geografía, arte).
* **Gestor de Audio Inmersivo (`AudioManager`):**
  * Música de fondo relajante que se detiene automáticamente cuando la app entra en segundo plano o recibe una llamada, reanudándose al volver.
  * Efectos sonoros de selección, acierto y victoria.
* **Sistema de Pistas & Monetización:**
  * Pistas consumibles que iluminan la primera letra de una palabra oculta.
  * Anuncios premiados para recargar pistas de forma gratuita.
  * Persistencia segura del saldo de pistas ante cierres de la app mediante `WidgetsBindingObserver`.

---

## 🏗️ Estructura del Código

```
sopa_de_letras/
├── lib/
│   ├── models/
│   │   ├── level_config.dart        # Configuración de matriz de letras y palabras a buscar
│   │   └── word_item.dart           # Coordenadas, estado encontrado y color
│   ├── managers/
│   │   ├── audio_manager.dart       # Reproducción de música BGM y efectos SFX
│   │   └── ad_manager.dart          # Gestión de banners y rewarded ads
│   ├── screens/
│   │   ├── game_screen.dart         # Cuadrícula interactiva con observador de ciclo de vida
│   │   ├── level_selection_screen.dart # Lista de niveles y progreso desbloqueado
│   │   └── home_screen.dart         # Menú de inicio y opciones de sonido
│   └── main.dart                    # Inicialización y tema visual
```

---

## 🚀 Puesta en Marcha

```bash
cd Sopa-de-letras/sopa_de_letras
flutter pub get
flutter run
```

---

**Desarrollado por Inventus Tech Studio** • *Liderado por Samuel Henríquez*
