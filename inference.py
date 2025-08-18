# inference.py
import argparse, json, torch
from PIL import Image
from torchvision import transforms

IMAGENET_CLASSES_URL = "https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt"

def load_labels():
    import urllib.request
    try:
        with urllib.request.urlopen(IMAGENET_CLASSES_URL, timeout=10) as r:
            return [l.strip() for l in r.read().decode("utf-8").splitlines()]
    except Exception:
        return [f"class_{i}" for i in range(1000)]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--model", default="/app/model.pt")
    ap.add_argument("--topk", type=int, default=3)
    args = ap.parse_args()

    device = "cpu"
    model = torch.jit.load(args.model, map_location=device)
    model.eval()

    preprocess = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]),
    ])

    img = Image.open(args.image).convert("RGB")
    x = preprocess(img).unsqueeze(0)

    with torch.no_grad():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)
        vals, idxs = probs.topk(args.topk, dim=1)

    labels = load_labels()
    out = [
        {
            "rank": i+1,
            "class_id": int(idx),
            "label": labels[int(idx)] if int(idx) < len(labels) else f"class_{int(idx)}",
            "prob": float(val),
        }
        for i, (val, idx) in enumerate(zip(vals[0], idxs[0]))
    ]
    print(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
