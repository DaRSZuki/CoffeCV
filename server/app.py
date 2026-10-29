"""Servidor de inferencia para la app CV Café.

Ejecutar:
    python -m uvicorn app:app --host 0.0.0.0 --port 8000

Endpoints:
    GET  /health      estado del servidor y del modelo
    GET  /diseases    base de conocimiento de enfermedades
    POST /predict     recibe una imagen (campo 'file') y devuelve el diagnóstico
"""
import io
import json
import time
from pathlib import Path

import torch
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, ImageOps
from torchvision import transforms

from train import build_model

ROOT = Path(__file__).resolve().parent
MODEL_PATH = ROOT / "models" / "coffee_model.pt"
KNOWLEDGE_PATH = ROOT.parent / "app" / "assets" / "diseases.json"

# Por debajo de este umbral el resultado se marca como "no concluyente".
CONFIDENCE_THRESHOLD = 0.55

DISPLAY_NAMES = {"sana": "Hoja sana"}

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
ckpt = torch.load(MODEL_PATH, map_location=device)
CLASSES = ckpt["classes"]
model = build_model(len(CLASSES), pretrained=False)
model.load_state_dict(ckpt["state_dict"])
model.to(device).eval()

preprocess = transforms.Compose([
    transforms.Resize(ckpt["img_size"]),
    transforms.CenterCrop(ckpt["img_size"]),
    transforms.ToTensor(),
    transforms.Normalize(ckpt["mean"], ckpt["std"]),
])

with open(KNOWLEDGE_PATH, encoding="utf-8") as f:
    KNOWLEDGE = {d["id"]: d for d in json.load(f)}

for cid in CLASSES:
    if cid != "sana":
        DISPLAY_NAMES[cid] = KNOWLEDGE.get(cid, {}).get("nombre", cid)

app = FastAPI(title="CV Café - Diagnóstico de enfermedades", version="1.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/health")
def health():
    return {"status": "ok", "device": str(device), "classes": CLASSES}


@app.get("/diseases")
def diseases():
    return list(KNOWLEDGE.values())


@torch.no_grad()
def classify(img: Image.Image):
    x = preprocess(img).unsqueeze(0).to(device)
    batch = torch.cat([x, torch.flip(x, dims=[3])])  # TTA: imagen + volteo horizontal
    probs = torch.softmax(model(batch), dim=1).mean(0)
    return probs.cpu().tolist()


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    data = await file.read()
    try:
        img = ImageOps.exif_transpose(Image.open(io.BytesIO(data))).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="El archivo no es una imagen válida.")

    t0 = time.perf_counter()
    probs = classify(img)
    elapsed_ms = round((time.perf_counter() - t0) * 1000, 1)

    ranking = sorted(
        ({"id": c, "nombre": DISPLAY_NAMES[c], "probabilidad": round(p, 4)} for c, p in zip(CLASSES, probs)),
        key=lambda r: r["probabilidad"], reverse=True,
    )
    top = ranking[0]
    return {
        "clase": top["id"],
        "nombre": top["nombre"],
        "confianza": top["probabilidad"],
        "sana": top["id"] == "sana",
        "concluyente": top["probabilidad"] >= CONFIDENCE_THRESHOLD,
        "probabilidades": ranking,
        "tiempo_ms": elapsed_ms,
    }
