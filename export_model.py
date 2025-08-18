# export_model.py
import argparse, torch
from torchvision.models import mobilenet_v2, MobileNet_V2_Weights

p = argparse.ArgumentParser()
p.add_argument("--out", required=True)
args = p.parse_args()

weights = MobileNet_V2_Weights.DEFAULT
model = mobilenet_v2(weights=weights)
model.eval()

example = torch.randn(1, 3, 224, 224)
with torch.no_grad():
    traced = torch.jit.trace(model, example)
traced.save(args.out)
print(f"Saved TorchScript to {args.out}")
