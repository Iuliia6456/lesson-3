
## Objective
- Automate ML environment setup (Docker, Python, pip, torch, torchvision, pillow, Django).  
- Export a pretrained PyTorch model (MobileNetV2) to TorchScript.  
- Create a Python inference service (`inference.py`) that predicts top-3 ImageNet classes.  
- Containerize the service in two images:
  - **Fat image**: large, good for debugging.  
  - **Slim image**: optimized for production.  
- Compare size, layers, and extra tools.

---

## Steps 

1. **Environment setup**  
   - Created `install_dev_tools.sh` to install Docker, Python (≥3.9), pip, torch, torchvision, pillow, Django.  
   - Verified versions and logged output to `install.log`.

2. **Model export**  
   - Used `export_model.py` to download MobileNetV2 pretrained weights from `torchvision.models`.  
   - Converted model to TorchScript format and saved to `model/mobilenet_v2.torchscript.pt`.

3. **Inference script**  
   - `inference.py` loads the TorchScript model.  
   - Takes an image input (`maltipoo.jpg`), preprocesses, and outputs top-3 predictions with probabilities.  
   - Example result (same for both images):  
     ```json
     [
      {"rank": 1, "class_id": 153, "label": "Maltese dog", "prob": 0.44237685203552246},
      {"rank": 2, "class_id": 204, "label": "Lhasa", "prob": 0.029016569256782532},
      {"rank": 3, "class_id": 265, "label": "toy poodle", "prob": 0.020915253087878227}
     ]
     ```

4. **Containerization**  
   - **Dockerfile.fat**: based on `python:3.10`, installs build tools (`git`, `gcc`, `curl`, `vim`), Python deps, model, and script.  
   - **Dockerfile.slim**: two-stage build with `python:3.10-slim`; first installs deps, final stage copies only runtime libraries + model + script.  
   - Built with:
     ```bash
     docker build -t mobilenet-fat -f Dockerfile.fat .
     docker build -t mobilenet-slim -f Dockerfile.slim .
     ```

---

## Results

| Metric              | Fat Image         | Slim Image       |
|----------------------|------------------|------------------|
| **Size**            | 2.04 GB          | 1.03 GB          |
| **Layer count**     | 20               | 18               |
| **Unnecessary tools** | apt-get, gcc, git, make, curl, vim | none |

Both images produce identical inference results.

- **Fat image** is easier for debugging and development, since it includes compilers and system tools.  
- **Slim image** is more suitable for production deployment, it is smaller, faster to pull.  
- The accuracy is identical, as both use the same TorchScript model.  

---

## Suggestions for Further Optimization

- **Pin versions** of torch/torchvision for reproducibility.  
- Remove cache files and `__pycache__` from the final layer.  
- Consider model quantization or ONNX Runtime to further reduce size and speed up inference.  
- Wrap the inference script in a lightweight API server (FastAPI or Flask) for easier integration.  
- Explore using `distroless` or `alpine` bases (if PyTorch wheel support allows).  

---

## Conclusion
We successfully created a PyTorch inference service with two Docker images.  
The **fat image** is large but convenient for development, while the **slim image** is production-ready, cutting the size in half and removing unnecessary tools without sacrificing functionality.


