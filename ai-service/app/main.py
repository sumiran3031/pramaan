from fastapi import FastAPI

app = FastAPI(
    title="Pramaan AI Service",
    description="OCR and document-extraction microservice for the Pramaan bid compliance platform.",
    version="0.1.0",
)


@app.get("/health")
def health_check():
    return {"status": "UP", "service": "pramaan-ai-service"}
