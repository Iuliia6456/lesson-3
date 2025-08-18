# Lesson 3 – ML Inference with Docker

This project demonstrates exporting a pre-trained MobileNetV2 model to TorchScript and performing inference inside Docker containers.
Two Docker images are provided: a **fat image** (with many dev tools) and a **slim image** (optimized multi-stage build).

---

## 📂 Repository Structure

```text
lesson-3/
├── inference.py          # Script for running inference on an image
├── export_model.py       # Script to export pretrained model to TorchScript
├── model.pt              # Exported TorchScript model
├── Dockerfile.fat        # Full-size Docker image
├── Dockerfile.slim       # Optimized multi-stage slim image
├── install_dev_tools.sh  # Environment setup script
├── REPORT.md             # Comparison report of fat vs slim images
├── README.md             # Instructions (current file)
└── assets/               # Folder with test images (maltipoo.jpg)
```

---

## 🛠️ Build Images

From the repo root, run:

```bash
docker build -t mobilenet-fat -f Dockerfile.fat .
docker build -t mobilenet-slim -f Dockerfile.slim .
```

---

## 🖼️ Run Inference

Test image (`maltipoo.jpg`) is inside the `assets/` folder. Then run:

```bash
docker run --rm -v "$PWD/assets:/data" mobilenet-fat --image /data/maltipoo.jpg --topk 3
docker run --rm -v "$PWD/assets:/data" mobilenet-slim --image /data/maltipoo.jpg --topk 3
```

```
