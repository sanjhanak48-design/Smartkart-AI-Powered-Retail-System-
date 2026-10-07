from fastapi import FastAPI

app = FastAPI(title="SmartKart API")


@app.get("/")
def home():
    return {
        "project": "SmartKart",
        "status": "running",
        "message": "SmartKart backend is alive!"
    }