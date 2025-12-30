#!/usr/bin/env python3
from fastapi import FastAPI, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import torch, tempfile, os

pipe, device = None, None


def load_model():
  global pipe, device
  from transformers import pipeline

  device = "mps" if torch.backends.mps.is_available() else "cuda" if torch.cuda.is_available() else "cpu"
  print(f"Loading MedASR on {device}...")
  pipe = pipeline("automatic-speech-recognition", model="google/medasr", device=device)
  print("Ready")


@asynccontextmanager
async def lifespan(app: FastAPI):
  load_model()
  yield


app = FastAPI(lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/")
async def root():
  return {"status": "running", "model": "google/medasr", "device": device}


@app.get("/v1/models")
async def models():
  return {"object": "list", "data": [{"id": "medasr", "object": "model", "owned_by": "google"}]}


@app.post("/v1/audio/transcriptions")
async def transcribe(
  file: UploadFile, model: str = Form(default="medasr"), response_format: str = Form(default="json")
):
  if not pipe:
    raise HTTPException(503, "Model not loaded")

  suffix = os.path.splitext(file.filename or ".wav")[1] or ".wav"
  with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as f:
    f.write(await file.read())
    path = f.name

  try:
    text = pipe(path, chunk_length_s=20, stride_length_s=2)["text"]
    text = (
      text.replace("</s>", "").replace("<s>", "").replace("{new paragraph}", "\n\n").replace("{new line}", "\n").strip()
    )
    return text if response_format == "text" else {"text": text}
  finally:
    os.unlink(path)


if __name__ == "__main__":
  import uvicorn

  uvicorn.run(app, host="127.0.0.1", port=8000)
