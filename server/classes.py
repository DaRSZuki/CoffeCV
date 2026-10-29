"""Definición de las clases del modelo y sus carpetas de origen.

Cada clase puede tomar imágenes de varias carpetas (dataset propio + datasets externos).
Las carpetas que no existan se ignoran.
"""
from pathlib import Path

DATA_ROOT = Path(__file__).resolve().parent.parent

# RoCoLe (Robusta Coffee Leaf Images): fotos de campo, descargadas con kagglehub.
ROCOLE = (DATA_ROOT / "datasets_externos" / "datasets" / "nirmalsankalana"
          / "rocole-a-robusta-coffee-leaf-images-dataset" / "versions" / "1")

# id de clase -> carpetas con las muestras (la primera es la del dataset propio)
CLASS_FOLDERS = {
    "sana": [DATA_ROOT / "Sanas", ROCOLE / "coffee___healthy"],
    "roya": [DATA_ROOT / "enfermedades" / "Roya del café", ROCOLE / "coffee___rust"],
    "ojo_de_gallo": [DATA_ROOT / "enfermedades" / "Ojo de gallo o Gotera"],
    "antracnosis": [DATA_ROOT / "enfermedades" / "Antracnosis"],
    "mancha_de_hierro": [DATA_ROOT / "enfermedades" / "Mancha de hierro"],
    "phoma": [DATA_ROOT / "enfermedades" / "Phoma"],
    "broca": [DATA_ROOT / "enfermedades" / "Broca del café"],
    "arana_roja": [ROCOLE / "coffee___red_spider_mite"],
}

CLASS_NAMES = list(CLASS_FOLDERS.keys())

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
