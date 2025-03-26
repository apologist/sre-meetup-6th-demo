from typing import Optional

import uvicorn
from fastapi import FastAPI, Form, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel

import argostranslate.translate

app = FastAPI()


templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")


class TranslationResponse(BaseModel):
    translated_text: str
    error: Optional[str] = None


@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/translate", response_model=TranslationResponse)
async def translate(
    text: str = Form(...),
    source_lang: str = Form("en"),
    target_lang: str = Form("es")
):
    if not text:
        return TranslationResponse(translated_text="", error="No text provided")
    
    try:        
        translated_text = argostranslate.translate.translate(text, source_lang, target_lang)
        return TranslationResponse(translated_text=translated_text)
    
    except Exception as e:
        return TranslationResponse(translated_text="", error=str(e))


if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
