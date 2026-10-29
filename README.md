#Información general
Proyecto realizado por David Ruiz y José Vásquez para el curso de seminario del estado actual de la tecnología, los datasets se encuentran libres en la web. 
Dejo uno de los utilizados 
import kagglehub

# Download latest version
path = kagglehub.dataset_download("nirmalsankalana/rocole-a-robusta-coffee-leaf-images-dataset")

print("Path to dataset files:", path)
Licencia MIT... 

Curso: Seminario del estado actual de la tecnología


El proyecto requiere de un servidor, pude usar su propia computadora como servidor local y conectarse a la red local



# CV Café — Diagnóstico de enfermedades del café con IA

Aplicación móvil (Flutter) + servidor de visión por computadora (Python / PyTorch).
La app toma la foto de la hoja, la envía al servidor, el servidor la clasifica y devuelve el diagnóstico.
La guía de enfermedades y tratamientos está dentro de la app y funciona sin conexión.

```
CVcafe/
├── Sanas/, enfermedades/      dataset de entrenamiento
├── server/                    servidor Python
│   ├── train.py               entrena el modelo -> models/coffee_model.pt
│   ├── app.py                 API FastAPI (/predict, /health, /diseases)
│   ├── classes.py             clases y carpetas del dataset
│   ├── entrenar.bat           atajo para reentrenar
│   └── iniciar_servidor.bat   atajo para levantar el servidor
└── app/                       aplicación Flutter
    ├── assets/diseases.json   base de conocimiento (la usa también el servidor)
    └── lib/
        ├── screens/           inicio, guía, ficha, cámara, resultado, ajustes
        ├── services/          cliente HTTP y repositorio de enfermedades
        └── models/, widgets/
```

## 1. Servidor

Ya instalado en `server/.venv` (Python 3.12, PyTorch con CUDA).

```bat
cd server
iniciar_servidor.bat
```

Queda escuchando en `http://0.0.0.0:8000`. Prueba rápida: abrir `http://localhost:8000/docs`.

Si Windows pregunta por el firewall, permita el acceso en redes **privadas** (necesario para que el teléfono llegue a la PC).

### Reentrenar el modelo

Al agregar fotos a las carpetas, ejecute `server\entrenar.bat` (≈ 10-15 min con la GPU).
La primera vez crea una caché de imágenes reducidas en `server/cache/`; si cambia o borra fotos, elimine esa carpeta.
Las métricas quedan en `server/models/metrics.json`.

Para agregar una enfermedad nueva: cree la carpeta, añádala en `server/classes.py` y agregue su ficha en `app/assets/diseases.json` con el mismo `id`.

## 2. App móvil

APK compilado: `app/build/app/outputs/flutter-apk/app-release.apk` — cópielo al teléfono e instálelo.

En la app, toque ⚙ (Ajustes) y escriba la dirección del servidor:

| Dónde corre la app | Dirección |
|---|---|
| Emulador de Android en esta PC | `http://10.0.2.2:8000` (valor por defecto) |
| Teléfono real en la misma Wi-Fi | `http://<IP de la PC>:8000` (la muestra `iniciar_servidor.bat`) |
| Servidor en la nube (futuro) | `https://su-dominio` |

Desarrollo: `C:\src\flutter\bin\flutter run` dentro de `app/` con el teléfono conectado por USB (depuración USB activada).

### Funciones

- **Guía de enfermedades**: ficha de cada enfermedad con síntomas, condiciones, impacto, frecuencia, tratamiento (cultural, biológico, químico), prevención y datos curiosos.
- **Identificar enfermedad**:
  - *Tiempo real*: interruptor que analiza continuamente lo que ve la cámara (≈1 resultado por segundo según la red).
  - *Captura*: foto → diagnóstico completo con probabilidades y guía de tratamiento.
  - *Galería*: analizar una foto existente.
  - Si la confianza es menor a 55 % el resultado se marca como **no concluyente**.

## Datos de entrenamiento

| Clase | Dataset propio | RoCoLe (campo) |
|---|---|---|
| Sana | 499 | 791 |
| Roya | 520 | 602 |
| Ojo de gallo | 513 | — |
| Antracnosis / Broca / Mancha de hierro / Phoma | 15 / 10 / 7 / 8 | — |
| Araña roja | — | 167 |

RoCoLe (*Robusta Coffee Leaf Images*, Kaggle `nirmalsankalana/rocole-a-robusta-coffee-leaf-images-dataset`)
se descarga en `datasets_externos/`. Es importante porque las fotos propias de Sana, Roya y Ojo de gallo
están tomadas sobre **fondo blanco**, y las de las enfermedades raras son fotos de campo. Sin fotos de campo
de hojas sanas, el modelo aprendía que "fondo de campo = enfermedad".

Para descargarlo de nuevo:

```bat
cd server
set KAGGLEHUB_CACHE=C:\CVcafe\datasets_externos
.venv\Scripts\python -c "import kagglehub; kagglehub.dataset_download('nirmalsankalana/rocole-a-robusta-coffee-leaf-images-dataset')"
```


