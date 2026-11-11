# Versiones actuales — 2026-10-19

Registro previo a investigar el desenfoque de los textos. No se cambiaron versiones.

Haxe comprobado ejecutando `haxe --version`: **4.3.4**.

## Dependencias usadas en la última compilación Windows release

Contrastadas con `export/release/windows/haxe/release.hxml` y el registro local de Haxelib.

| Dependencia | Versión | Selección |
| --- | --- | --- |
| Flixel | 5.6.1 | Fijada en Project.xml |
| Flixel Addons | 3.2.2 | Fijada en Project.xml |
| Lime | 8.1.2 | Activa localmente |
| OpenFL | 9.5.1 | Activa localmente |
| hxVLC | 2.2.6 | Fijada en Project.xml |
| hscript-iris | 1.1.3 | Fijada en Project.xml |
| hscript | 2.7.0 | Dependencia indirecta |
| tjson | 1.4.0 | Fijada en Project.xml |
| hxdiscord_rpc | 1.2.4 | Fijada en Project.xml |
| linc_luajit | 0.0.8 declarada | Checkout git |
| hxcpp | 4.3.0 declarada | Checkout git |
| flxanimate | 4.0.0 declarada | Checkout git |
| tink_core | 1.26.0 | Dependencia indirecta |
| grig.audio | git | BASE_GAME_FILES |
| funkin.vis | git | BASE_GAME_FILES |

Las versiones declaradas de los checkouts git no identifican por sí solas el commit instalado.
El registro generado no demuestra qué versión de Haxe compiló ese ejecutable: 4.3.4 es la versión comprobada actualmente.

## Otras librerías activas instaladas

Estar instalada/activa no implica que se incluya en esta compilación.

| Librería | Selección activa |
| --- | --- |
| discord_rpc | git |
| extension-androidtools | git |
| flixel-tools | 1.5.1 |
| flixel-ui | 2.6.4 |
| hxCodec | 2.5.1 |
| hxcpp-debug-server | dev: extensión de VS Code vshaxe.hxcpp-debugger-1.2.4 |
| lime-samples | 7.0.0 |
| SScript | 21.0.1 |

## Alternativas instaladas, no activas

- OpenFL: 9.3.3, 9.5.0, 9.5.2.
- Lime: 8.3.0, 8.3.1, 8.3.2.
- Flixel: 6.1.2.
- Flixel Addons: 3.3.2.
- hxVLC: 2.0.1.
- hxcpp: 4.3.2 empaquetada (actualmente se usa git).
- linc_luajit: 0.0.7 empaquetada (actualmente se usa git).
- extension-androidtools: 1.7.0, 2.2.2.

## Método de comprobación

`haxelib list` falló en este entorno. Se leyeron las selecciones `.current` / `.dev` de `C:/HaxeToolkit/haxe/lib`, además de Project.xml y el HXML generado. No se instalaron, actualizaron ni sustituyeron librerías.
