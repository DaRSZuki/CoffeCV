"""Entrena el clasificador de enfermedades de hojas de café.

Uso:
    python train.py                 # entrenamiento completo
    python train.py --epochs 5      # prueba rápida

Pasos:
  1. Redimensiona todas las imágenes del dataset a una caché local (rápido de leer).
  2. Divide en entrenamiento / validación de forma estratificada.
  3. Ajusta (fine-tuning) una EfficientNet-B0 preentrenada en ImageNet.
     Las clases con pocas muestras se sobremuestrean y se usa aumento de datos fuerte.
  4. Guarda el mejor modelo (por exactitud balanceada) en models/coffee_model.pt
"""
import argparse
import json
import random
from collections import Counter
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
from PIL import Image, ImageOps
from sklearn.metrics import classification_report, confusion_matrix, balanced_accuracy_score
from torch.utils.data import DataLoader, Dataset, WeightedRandomSampler
from torchvision import models, transforms

from classes import CLASS_FOLDERS, CLASS_NAMES, IMAGE_EXTS

ROOT = Path(__file__).resolve().parent
CACHE_DIR = ROOT / "cache"
MODEL_DIR = ROOT / "models"
CACHE_SIZE = 320  # lado corto de la imagen en caché
IMG_SIZE = 224
MEAN, STD = [0.485, 0.456, 0.406], [0.229, 0.224, 0.225]


def build_cache():
    """Convierte cada imagen a JPEG RGB redimensionado. Devuelve [(ruta, idx_clase)]."""
    samples = []
    for idx, name in enumerate(CLASS_NAMES):
        out_dir = CACHE_DIR / name
        out_dir.mkdir(parents=True, exist_ok=True)
        files = []
        for folder in CLASS_FOLDERS[name]:
            if not folder.is_dir():
                print(f"  [aviso] no existe {folder}")
                continue
            prefix = "ext_" if "datasets_externos" in folder.parts else ""
            files += [(prefix, p) for p in sorted(folder.iterdir()) if p.suffix.lower() in IMAGE_EXTS]
        counters = Counter()
        for prefix, src in files:
            dst = out_dir / f"{prefix}{counters[prefix]:04d}.jpg"
            counters[prefix] += 1
            if not dst.exists():
                try:
                    img = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
                except Exception as e:  # imagen corrupta
                    print(f"  [omitida] {src.name}: {e}")
                    continue
                img = ImageOps.contain(img, (CACHE_SIZE * 4, CACHE_SIZE * 4))
                scale = CACHE_SIZE / min(img.size)
                if scale < 1:
                    img = img.resize((round(img.width * scale), round(img.height * scale)), Image.BICUBIC)
                img.save(dst, quality=92)
            samples.append((dst, idx))
        print(f"  {name:<18} {len(files):>4} imágenes")
    return samples


def stratified_split(samples, val_frac, seed):
    rng = random.Random(seed)
    by_class = {}
    for s in samples:
        by_class.setdefault(s[1], []).append(s)
    train, val = [], []
    for items in by_class.values():
        rng.shuffle(items)
        n_val = max(2, round(len(items) * val_frac))
        val += items[:n_val]
        train += items[n_val:]
    return train, val


class LeafDataset(Dataset):
    def __init__(self, samples, transform):
        self.samples = samples
        self.transform = transform

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, i):
        path, label = self.samples[i]
        return self.transform(Image.open(path).convert("RGB")), label


train_tf = transforms.Compose([
    transforms.RandomResizedCrop(IMG_SIZE, scale=(0.35, 1.0), ratio=(0.75, 1.33)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomVerticalFlip(),
    transforms.RandomRotation(25),
    transforms.ColorJitter(0.35, 0.35, 0.3, 0.04),
    transforms.RandomApply([transforms.GaussianBlur(5, sigma=(0.1, 2.0))], p=0.25),
    transforms.ToTensor(),
    transforms.Normalize(MEAN, STD),
    transforms.RandomErasing(p=0.2, scale=(0.02, 0.12)),
])

eval_tf = transforms.Compose([
    transforms.Resize(IMG_SIZE),
    transforms.CenterCrop(IMG_SIZE),
    transforms.ToTensor(),
    transforms.Normalize(MEAN, STD),
])


def build_model(num_classes, pretrained=True):
    weights = models.EfficientNet_B0_Weights.IMAGENET1K_V1 if pretrained else None
    model = models.efficientnet_b0(weights=weights)
    in_f = model.classifier[1].in_features
    model.classifier = nn.Sequential(nn.Dropout(0.4), nn.Linear(in_f, num_classes))
    return model


@torch.no_grad()
def evaluate(model, loader, device):
    model.eval()
    preds, labels = [], []
    for x, y in loader:
        x = x.to(device)
        with torch.autocast(device_type=device.type, enabled=device.type == "cuda"):
            logits = model(x) + model(torch.flip(x, dims=[3]))  # TTA: volteo horizontal
        preds += logits.argmax(1).cpu().tolist()
        labels += y.tolist()
    return np.array(labels), np.array(preds)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--warmup-epochs", type=int, default=3, help="épocas con el backbone congelado")
    ap.add_argument("--batch", type=int, default=32)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--val-frac", type=float, default=0.15)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()

    random.seed(args.seed)
    torch.manual_seed(args.seed)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Dispositivo: {device}")

    print("Preparando caché de imágenes...")
    samples = build_cache()
    train_s, val_s = stratified_split(samples, args.val_frac, args.seed)
    counts = Counter(l for _, l in train_s)
    print(f"Entrenamiento: {len(train_s)}  Validación: {len(val_s)}")

    # Sobremuestreo: cada clase aparece aprox. con la misma frecuencia por época.
    sample_w = [1.0 / counts[l] for _, l in train_s]
    sampler = WeightedRandomSampler(sample_w, num_samples=len(train_s), replacement=True)
    train_dl = DataLoader(LeafDataset(train_s, train_tf), batch_size=args.batch, sampler=sampler,
                          num_workers=args.workers, pin_memory=True, persistent_workers=args.workers > 0)
    val_dl = DataLoader(LeafDataset(val_s, eval_tf), batch_size=args.batch, num_workers=args.workers)

    model = build_model(len(CLASS_NAMES)).to(device)
    criterion = nn.CrossEntropyLoss(label_smoothing=0.1)
    scaler = torch.amp.GradScaler(enabled=device.type == "cuda")

    def make_opt(stage):
        if stage == "head":
            for p in model.features.parameters():
                p.requires_grad = False
            params = model.classifier.parameters()
            return torch.optim.AdamW(params, lr=args.lr, weight_decay=1e-4), None
        for p in model.parameters():
            p.requires_grad = True
        opt = torch.optim.AdamW([
            {"params": model.features.parameters(), "lr": args.lr * 0.3},
            {"params": model.classifier.parameters(), "lr": args.lr},
        ], weight_decay=1e-4)
        steps = (args.epochs - args.warmup_epochs) * len(train_dl)
        return opt, torch.optim.lr_scheduler.OneCycleLR(
            opt, max_lr=[args.lr * 0.3, args.lr], total_steps=max(steps, 1), pct_start=0.15)

    MODEL_DIR.mkdir(exist_ok=True)
    best = -1.0
    opt, sched = make_opt("head")
    for epoch in range(1, args.epochs + 1):
        if epoch == args.warmup_epochs + 1:
            opt, sched = make_opt("full")
        model.train()
        total, n = 0.0, 0
        for x, y in train_dl:
            x, y = x.to(device, non_blocking=True), y.to(device, non_blocking=True)
            opt.zero_grad(set_to_none=True)
            with torch.autocast(device_type=device.type, enabled=device.type == "cuda"):
                loss = criterion(model(x), y)
            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()
            if sched:
                sched.step()
            total += loss.item() * len(y)
            n += len(y)

        y_true, y_pred = evaluate(model, val_dl, device)
        bal = balanced_accuracy_score(y_true, y_pred)
        acc = (y_true == y_pred).mean()
        # La exactitud balanceada sola es muy ruidosa (clases con 2 imágenes de validación),
        # por eso se combina con la exactitud global para elegir el mejor modelo.
        score = 0.5 * bal + 0.5 * acc
        flag = ""
        if score >= best:
            best = score
            torch.save({"state_dict": model.state_dict(), "classes": CLASS_NAMES,
                        "img_size": IMG_SIZE, "mean": MEAN, "std": STD, "arch": "efficientnet_b0"},
                       MODEL_DIR / "coffee_model.pt")
            flag = "  <- mejor"
        print(f"Época {epoch:>2}/{args.epochs}  pérdida {total / n:.4f}  "
              f"val_acc {acc:.3f}  val_acc_balanceada {bal:.3f}{flag}")

    # Reporte final con el mejor modelo
    ckpt = torch.load(MODEL_DIR / "coffee_model.pt", map_location=device)
    model.load_state_dict(ckpt["state_dict"])
    y_true, y_pred = evaluate(model, val_dl, device)
    labels = list(range(len(CLASS_NAMES)))
    report = classification_report(y_true, y_pred, labels=labels, target_names=CLASS_NAMES,
                                   zero_division=0, output_dict=True)
    print(classification_report(y_true, y_pred, labels=labels, target_names=CLASS_NAMES, zero_division=0))
    cm = confusion_matrix(y_true, y_pred, labels=labels)
    print("Matriz de confusión (filas = real, columnas = predicho):")
    print("  ", CLASS_NAMES)
    print(cm)
    is_ext = np.array([p.name.startswith("ext_") for p, _ in val_s])
    by_source = {}
    for tag, mask in (("dataset_propio", ~is_ext), ("dataset_externo_campo", is_ext)):
        if mask.any():
            by_source[tag] = float((y_true[mask] == y_pred[mask]).mean())
            print(f"Exactitud {tag}: {by_source[tag]:.3f} ({mask.sum()} imágenes)")
    with open(MODEL_DIR / "metrics.json", "w", encoding="utf-8") as f:
        json.dump({"balanced_accuracy": balanced_accuracy_score(y_true, y_pred), "report": report,
                   "confusion_matrix": cm.tolist(), "classes": CLASS_NAMES, "accuracy_by_source": by_source,
                   "train_counts": {CLASS_NAMES[k]: v for k, v in counts.items()}}, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
