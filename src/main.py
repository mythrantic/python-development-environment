"""
python-development-environment API 

Example python project standard structure with FastAPI backend and static frontend
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from .routes import home_routes
import os
from loguru import logger
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from dotenv import load_dotenv
load_dotenv()

# Global state for ML models
ml_models = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load ML models on startup and clean up on shutdown."""
    # Load the example AI model loader
    logger.info("Loading example AI model loader...")
    from python_development_environment.module import ExampleAIModelLoader
    example_ai_model_loader = ExampleAIModelLoader()
    logger.info("ExampleAIModelLoader instance created")
    
    # Trigger actual model loading (not just initialization)
    logger.info("Calling load_model()...")
    example_ai_model_loader.load_model()
    logger.info("load_model() returned")
    
    ml_models["example_ai_model_loader"] = example_ai_model_loader
    logger.info("Example AI model loader loaded and ready")
    
    # Store in app state so routes can access it
    app.state.ml_models = ml_models
    
    yield
    
    # Clean up the ML models and release resources
    logger.info("Shutting down and cleaning up ML models...")
    ml_models.clear()


app = FastAPI(
    title="python development environment API",
    description="""
An example Python project structure with FastAPI backend and static frontend standard setup.
""",
    version="2.0.0",
    lifespan=lifespan,
)

# Include routers
app.include_router(home_routes.router)

# CORS Middleware
allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:5173,https://python-development-environment.valiantlynx.com").split(
    ","
)
logger.info("ALLOWED_ORIGINS:", allowed_origins)
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Prometheus metrics
Instrumentator().instrument(app).expose(app)

# Mount static files for frontend at root (must be last to avoid overriding API routes)
frontend_path = Path(__file__).parent.parent / "frontend"
if frontend_path.exists():
    app.mount("/", StaticFiles(directory=str(frontend_path), html=True), name="frontend")
    logger.info(f"Mounted frontend from {frontend_path}")
else:
    logger.warning(f"Frontend directory not found at {frontend_path}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
